import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import '../supabase_manager.dart';
import '../utils/error_messages.dart';
import 'course_editor_page.dart';
import '../constants.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final service = CourseService();
  List<Course> courses = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      if (SupabaseManager.initialized) {
        final uid = SupabaseManager.client.auth.currentUser?.id;
        if (uid == null) {
          error = 'Авторизуйтесь, чтобы видеть свои курсы.';
        } else {
          final data = await SupabaseManager.client.from('courses').select().eq('owner', uid).order('created_at');
          courses = data.map<Course>((e) => Course.fromMap(e)).toList();
        }
      } else {
        error = 'Supabase не сконфигурирован.';
      }
    } catch (e) {
      error = humanizeAuthError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createCourseDialog() async {
    final title = TextEditingController();
    final price = TextEditingController(text: '0');
    String category = AppCategories.other;
    final imageUrl = TextEditingController(text: '');
    final formKey = GlobalKey<FormState>();
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Создать курс'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Название'), validator: (v) => (v==null||v.isEmpty) ? 'Введите название' : null),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                items: AppCategories.all.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: const InputDecoration(labelText: 'Раздел'),
                onChanged: (v) { if (v!=null) category = v; },
              ),
              const SizedBox(height: 10),
              TextFormField(controller: imageUrl, decoration: const InputDecoration(labelText: 'Ссылка на картинку (URL)')),
              const SizedBox(height: 10),
              TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена, ₽')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () async { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Создать')),
        ],
      ),
    );
    if (created == true) {
      try {
        final uid = SupabaseManager.client.auth.currentUser?.id;
        if (uid == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала войдите.')));
          return;
        }
        await SupabaseManager.client.from('courses').insert({
          'title': title.text.trim(),
          'category': category,
          'price': int.tryParse(price.text) ?? 0,
          'author': 'Вы',
          'owner': uid,
          'description': '',
          'image_url': imageUrl.text.trim(),
        });
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Курс создан')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои курсы'), actions: [
        IconButton(onPressed: _createCourseDialog, icon: const Icon(Icons.add)),
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: error != null
                  ? Center(child: Text(error!))
                  : ListView.separated(
                      itemCount: courses.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final c = courses[i];
                        return ListTile(
                          leading: const Icon(Icons.school),
                          title: Text(c.title),
                          subtitle: Text('Просмотры: ${c.views}   ❤ ${c.likes}   ⭐ ${c.rating.toStringAsFixed(1)}'),
                          trailing: Text('${c.price} ₽'),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseEditorPage(course: c)));
                            await _load();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
