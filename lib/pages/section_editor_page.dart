import 'package:flutter/material.dart';
import '../supabase_manager.dart';
import '../utils/error_messages.dart';
import '../services/storage_service.dart';

class SectionEditorPage extends StatefulWidget {
  final String sectionId;
  final String sectionTitle;
  const SectionEditorPage({super.key, required this.sectionId, required this.sectionTitle});

  @override
  State<SectionEditorPage> createState() => _SectionEditorPageState();
}

class _SectionEditorPageState extends State<SectionEditorPage> {
  List<Map<String, dynamic>> lessons = [];
  List<Map<String, dynamic>> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = SupabaseManager.client;
    final sid = widget.sectionId;
    final l = await sb.from('section_lessons').select().eq('section_id', sid).order('order_index');
    final t = await sb.from('course_tasks').select().eq('section_id', sid).order('order_index');
    setState(() { lessons = List<Map<String,dynamic>>.from(l); tasks = List<Map<String,dynamic>>.from(t); loading = false; });
  }

  Future<void> _editLesson([Map<String,dynamic>? item]) async {
    final title = TextEditingController(text: item?['title'] ?? '');
    final content = TextEditingController(text: item?['content'] ?? '');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(item==null? 'Новый урок' : 'Изменить урок'),
      content: Form(key: formKey, child: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Название'), validator: (v)=>(v==null||v.isEmpty)?'Введите название':null),
        const SizedBox(height: 10),
        TextFormField(controller: content, maxLines: 8, decoration: const InputDecoration(labelText: 'Содержание (можно вставлять ссылки на изображения/видео)')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final url = await StorageService().pickAndUpload(bucket: 'course-covers', pathPrefix: 'lesson-media');
                if (url != null) {
                  content.text = content.text + '\n![]($url)\n';
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Изображение добавлено в текст')));
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
              }
            }, icon: const Icon(Icons.image), label: const Text('Добавить изображение')),
        ),
      ]))),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Отмена')),
        FilledButton(onPressed: (){ if(formKey.currentState!.validate()) Navigator.pop(context,true); }, child: const Text('Сохранить')),
      ],
    ));
    if (ok==true) {
      try {
        if (item==null) {
          final count = await SupabaseManager.client.from('section_lessons').select().eq('section_id', widget.sectionId);
          await SupabaseManager.client.from('section_lessons').insert({'section_id': widget.sectionId, 'title': title.text.trim(), 'content': content.text, 'order_index': (count as List).length});
        } else {
          await SupabaseManager.client.from('section_lessons').update({'title': title.text.trim(), 'content': content.text}).eq('id', item['id']);
        }
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  Future<void> _delete(String table, String id) async {
    try {
      await SupabaseManager.client.from(table).delete().eq('id', id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Раздел: ${widget.sectionTitle}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      const Text('Уроки', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(onPressed: ()=>_editLesson(), icon: const Icon(Icons.add))
                    ]),
                    ...lessons.map((l)=>ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(l['title'] ?? ''),
                      subtitle: Text((l['content'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(onPressed: ()=>_editLesson(l), icon: const Icon(Icons.edit)),
                        IconButton(onPressed: ()=>_delete('section_lessons', l['id']), icon: const Icon(Icons.delete)),
                      ]),
                    )),
                    const Divider(height: 32),
                    Row(children: const [Text('Задания', style: TextStyle(fontWeight: FontWeight.w600))]),
                    ...tasks.map((t)=>ListTile(
                      leading: const Icon(Icons.task),
                      title: Text(t['question'] ?? ''),
                      subtitle: Text('Тип: ${t['type']}'),
                      trailing: IconButton(onPressed: ()=>_delete('course_tasks', t['id']), icon: const Icon(Icons.delete)),
                    )),
                  ],
                ),
              ),
            ]),
    );
  }
}

