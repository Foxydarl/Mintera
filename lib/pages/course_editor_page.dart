import 'package:flutter/material.dart';
import '../models/course.dart';
import '../constants.dart';
import '../supabase_manager.dart';
import '../utils/error_messages.dart';
import '../services/storage_service.dart';

class CourseEditorPage extends StatefulWidget {
  final Course course;
  const CourseEditorPage({super.key, required this.course});
  @override
  State<CourseEditorPage> createState() => _CourseEditorScaffoldState();
}

class _CourseEditorScaffoldState extends State<CourseEditorPage> {
  late TextEditingController title;
  late TextEditingController descr;
  late TextEditingController price;
  late TextEditingController imageUrl;
  String category = AppCategories.other;
  bool saving = false;
  List<Map<String, dynamic>> sections = [];
  String? coverUrl;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    title = TextEditingController(text: c.title);
    descr = TextEditingController(text: c.description);
    price = TextEditingController(text: c.price.toString());
    imageUrl = TextEditingController(text: c.imageUrl);
    category = c.category;
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final data = await SupabaseManager.client.from('course_sections').select().eq('course_id', widget.course.id).order('order_index');
      setState(() => sections = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await SupabaseManager.client.from('courses').update({
        'title': title.text.trim(),
        'description': descr.text.trim(),
        'price': int.tryParse(price.text) ?? 0,
        'image_url': imageUrl.text.trim(),
        'category': category,
      }).eq('id', widget.course.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Курс сохранён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addSection() async {
    final t = TextEditingController();
    final descrCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый раздел'),
        content: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Название раздела')),
            const SizedBox(height: 10),
            TextField(controller: descrCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Описание раздела')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Добавить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final index = sections.length;
        final row = await SupabaseManager.client.from('course_sections').insert({
          'course_id': widget.course.id,
          'title': t.text.trim(),
          'description': descrCtrl.text.trim(),
          'order_index': index,
        }).select().single();
        setState(() => sections.add(row));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактор курса'), actions: [
        TextButton(onPressed: saving ? null : _save, child: saving ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2)) : const Text('Сохранить')),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(
              width: 400,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')), 
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  items: AppCategories.all.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v!=null) setState(() => category = v); },
                  decoration: const InputDecoration(labelText: 'Раздел'),
                ),
                const SizedBox(height: 10),
                TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена, ₽')), 
                const SizedBox(height: 10),
                TextField(controller: imageUrl, decoration: const InputDecoration(labelText: 'Ссылка на обложку (URL)')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final url = await StorageService().pickAndUpload(bucket: 'course-covers', pathPrefix: 'covers');
                      if (url != null) {
                        setState(() {
                          imageUrl.text = url;
                          coverUrl = url;
                        });
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
                    }
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Загрузить картинку'),
                ),
              ]),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: descr, maxLines: 6, decoration: const InputDecoration(labelText: 'Описание')), 
                const SizedBox(height: 10),
                Row(children: [
                  FilledButton.icon(onPressed: _addSection, icon: const Icon(Icons.add), label: const Text('Добавить раздел')),
                ]),
                const SizedBox(height: 10),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sections.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final item = sections.removeAt(oldIndex);
                    sections.insert(newIndex, item);
                    setState(() {});
                    // Update order_index in DB
                    for (var i = 0; i < sections.length; i++) {
                      await SupabaseManager.client.from('course_sections').update({'order_index': i}).eq('id', sections[i]['id']);
                    }
                  },
                  itemBuilder: (_, i) {
                    final l = sections[i];
                    return ListTile(
                      key: ValueKey(l['id']),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(l['title'] ?? ''),
                      subtitle: Text((l['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _editSection(l)),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'add_lesson') _addLessonToSection(l['id']);
                            if (v == 'add_task') _addTaskToSection(l['id']);
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'add_lesson', child: Text('Добавить урок')),
                            PopupMenuItem(value: 'add_task', child: Text('Добавить задание')),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _editSection(Map<String, dynamic> section) async {
    final t = TextEditingController(text: section['title'] ?? '');
    final d = TextEditingController(text: section['description'] ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редактировать раздел'),
        content: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Название раздела')),
            const SizedBox(height: 10),
            TextField(controller: d, maxLines: 4, decoration: const InputDecoration(labelText: 'Описание')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await SupabaseManager.client
            .from('course_sections')
            .update({'title': t.text.trim(), 'description': d.text.trim()}).eq('id', section['id']);
        await _loadSections();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  Future<void> _addLessonToSection(String sectionId) async {
    final t = TextEditingController();
    final content = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый урок в разделе'),
        content: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Название урока')),
            const SizedBox(height: 10),
            TextField(controller: content, maxLines: 6, decoration: const InputDecoration(labelText: 'Содержание')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Добавить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final count = await SupabaseManager.client.from('section_lessons').select().eq('section_id', sectionId);
        await SupabaseManager.client.from('section_lessons').insert({
          'section_id': sectionId,
          'title': t.text.trim(),
          'content': content.text.trim(),
          'order_index': (count as List).length,
        });
        await _loadSections();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  Future<void> _addTaskToSection(String sectionId) async {
    String type = 'multiple_choice';
    final q = TextEditingController();
    final options = TextEditingController(text: 'Вариант 1;Вариант 2;Вариант 3');
    final answer = TextEditingController();
    final lang = TextEditingController(text: 'javascript');
    final template = TextEditingController(text: 'function solve(){\n  // напишите код\n}\nconsole.log("ok")');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новое задание'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'multiple_choice', child: Text('Выбор из вариантов')),
                  DropdownMenuItem(value: 'free_text', child: Text('Свободный ответ')),
                  DropdownMenuItem(value: 'code', child: Text('Код-задача')),
                ],
                onChanged: (v) { if (v!=null) type = v; },
                decoration: const InputDecoration(labelText: 'Тип задания'),
              ),
              const SizedBox(height: 10),
              TextFormField(controller: q, decoration: const InputDecoration(labelText: 'Вопрос/описание'), validator: (v)=> (v==null||v.isEmpty)?'Введите описание':null),
              if (type == 'multiple_choice') ...[
                const SizedBox(height: 10),
                TextFormField(controller: options, decoration: const InputDecoration(labelText: 'Варианты через ;')),
                const SizedBox(height: 10),
                TextFormField(controller: answer, decoration: const InputDecoration(labelText: 'Правильный ответ (точное совпадение)')),
              ] else if (type == 'free_text') ...[
                const SizedBox(height: 10),
                TextFormField(controller: answer, decoration: const InputDecoration(labelText: 'Ожидаемый ответ')),
              ] else ...[
                const SizedBox(height: 10),
                TextFormField(controller: lang, decoration: const InputDecoration(labelText: 'Язык (javascript)')),
                const SizedBox(height: 10),
                TextFormField(controller: template, maxLines: 6, decoration: const InputDecoration(labelText: 'Шаблон кода')),
              ]
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Добавить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final count = await SupabaseManager.client.from('course_tasks').select().eq('section_id', sectionId);
        await SupabaseManager.client.from('course_tasks').insert({
          'section_id': sectionId,
          'type': type,
          'question': q.text.trim(),
          if (type == 'multiple_choice') 'options': (options.text.split(';').map((e)=>e.trim()).toList()),
          if (type != 'code') 'answer': answer.text.trim(),
          if (type == 'code') 'code_language': lang.text.trim(),
          if (type == 'code') 'code_template': template.text,
          'order_index': (count as List).length,
        });
        await _loadSections();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }
}
