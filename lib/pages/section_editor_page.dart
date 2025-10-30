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
  bool hasSubsections = false;
  List<Map<String, dynamic>> subsections = [];
  String? activeSubsectionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = SupabaseManager.client;
    final sid = widget.sectionId;
    try {
      final subs = await sb.from('course_subsections').select().eq('section_id', sid).order('order_index');
      hasSubsections = true;
      subsections = List<Map<String, dynamic>>.from(subs);
      activeSubsectionId ??= subsections.isNotEmpty ? subsections.first['id'] as String : null;
    } catch (_) {
      hasSubsections = false;
    }

    Future<List<Map<String, dynamic>>> _selLessons() async {
      try {
        if (hasSubsections && activeSubsectionId != null) {
          return List<Map<String, dynamic>>.from(
              await sb.from('section_lessons').select().eq('subsection_id', activeSubsectionId as Object).order('order_index'));
        }
        return List<Map<String, dynamic>>.from(
            await sb.from('section_lessons').select().eq('section_id', sid).order('order_index'));
      } catch (_) {
        return [];
      }
    }

    Future<List<Map<String, dynamic>>> _selTasks() async {
      try {
        if (hasSubsections && activeSubsectionId != null) {
          return List<Map<String, dynamic>>.from(
              await sb.from('course_tasks').select().eq('subsection_id', activeSubsectionId as Object).order('order_index'));
        }
        return List<Map<String, dynamic>>.from(
            await sb.from('course_tasks').select().eq('section_id', sid).order('order_index'));
      } catch (_) {
        return [];
      }
    }

    final l = await _selLessons();
    final t = await _selTasks();
    if (mounted) setState(() {
      lessons = l;
      tasks = t;
      loading = false;
    });
  }

  Future<void> _editLesson([Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title'] ?? '');
    final content = TextEditingController(text: item?['content'] ?? '');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Новый урок' : 'Изменить урок'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Название'), validator: (v) => (v == null || v.isEmpty) ? 'Введите название' : null),
              const SizedBox(height: 10),
              TextFormField(controller: content, maxLines: 8, decoration: const InputDecoration(labelText: 'Содержание (ссылки на изображения/видео)')),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final url = await StorageService().pickAndUpload(bucket: 'course-covers', pathPrefix: 'lesson-media');
                      if (url != null) {
                        content.text = content.text + '\n![]($url)\n';
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Изображение добавлено')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Добавить изображение'),
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        if (item == null) {
          final count = await SupabaseManager.client.from('section_lessons').select().eq('section_id', widget.sectionId);
          await SupabaseManager.client.from('section_lessons').insert({
            'section_id': widget.sectionId,
            if (activeSubsectionId != null) 'subsection_id': activeSubsectionId,
            'title': title.text.trim(),
            'content': content.text,
            'order_index': (count as List).length,
          });
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
                    if (hasSubsections) ...[
                      Row(children: [
                        const Text('Подраздел', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: activeSubsectionId,
                          items: subsections.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['title'] ?? 'Без названия'))).toList(),
                          onChanged: (v) { setState(() => activeSubsectionId = v); _load(); },
                        ),
                        const Spacer(),
                        IconButton(onPressed: _addSubsection, icon: const Icon(Icons.add)),
                      ]),
                      const SizedBox(height: 12),
                    ],
                    Row(children: [
                      const Text('Уроки', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(onPressed: () => _editLesson(), icon: const Icon(Icons.add))
                    ]),
                    ...lessons.map((l) => ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(l['title'] ?? ''),
                          subtitle: Text((l['content'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(onPressed: () => _editLesson(l), icon: const Icon(Icons.edit)),
                            IconButton(onPressed: () => _delete('section_lessons', l['id']), icon: const Icon(Icons.delete)),
                          ]),
                        )),
                    const Divider(height: 32),
                    Row(children: [
                      const Text('Задания', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(onPressed: _addTask, icon: const Icon(Icons.add))
                    ]),
                    ...tasks.map((t) => ListTile(
                          leading: const Icon(Icons.task),
                          title: Text(t['question'] ?? ''),
                          subtitle: Text('Тип: ${t['type']}'),
                          trailing: IconButton(onPressed: () => _delete('course_tasks', t['id']), icon: const Icon(Icons.delete)),
                        )),
                    const Divider(height: 32),
                    const Text('Порядок элементов', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    MixedOrdering(lessons: lessons, tasks: tasks, onReorder: _reorderMixed),
                  ],
                ),
              ),
            ]),
    );
  }

  Future<void> _addSubsection() async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый подраздел'),
        content: TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Создать')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final row = await SupabaseManager.client
            .from('course_subsections')
            .insert({'section_id': widget.sectionId, 'title': title.text.trim(), 'order_index': subsections.length})
            .select()
            .single();
        subsections.add(row);
        activeSubsectionId = row['id'] as String;
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }

  Future<void> _reorderMixed(List<ItemRef> order) async {
    for (var i = 0; i < order.length; i++) {
      final it = order[i];
      if (it.kind == 'lesson') {
        await SupabaseManager.client.from('section_lessons').update({'order_index': i}).eq('id', it.id);
      } else {
        await SupabaseManager.client.from('course_tasks').update({'order_index': i}).eq('id', it.id);
      }
    }
    await _load();
  }

  Future<void> _addTask() async {
    String type = 'multiple_choice';
    final q = TextEditingController();
    final options = TextEditingController(text: 'Вариант 1;Вариант 2;Вариант 3');
    final answer = TextEditingController();
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
                ],
                onChanged: (v) { if (v!=null) type = v; },
                decoration: const InputDecoration(labelText: 'Тип задания'),
              ),
              const SizedBox(height: 10),
              TextFormField(controller: q, decoration: const InputDecoration(labelText: 'Вопрос/описание'), validator: (v)=>(v==null||v.isEmpty)?'Введите описание':null),
              if (type == 'multiple_choice') ...[
                const SizedBox(height: 10),
                TextFormField(controller: options, decoration: const InputDecoration(labelText: 'Варианты через ;')),
                const SizedBox(height: 10),
                TextFormField(controller: answer, decoration: const InputDecoration(labelText: 'Правильный ответ')),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Отмена')),
          FilledButton(onPressed: (){ if(formKey.currentState!.validate()) Navigator.pop(context,true); }, child: const Text('Добавить')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final count = await SupabaseManager.client.from('course_tasks').select().eq(hasSubsections && activeSubsectionId!=null ? 'subsection_id' : 'section_id', hasSubsections && activeSubsectionId!=null ? activeSubsectionId! : widget.sectionId);
        await SupabaseManager.client.from('course_tasks').insert({
          if (hasSubsections && activeSubsectionId!=null) 'subsection_id': activeSubsectionId,
          if (!(hasSubsections && activeSubsectionId!=null)) 'section_id': widget.sectionId,
          'type': type,
          'question': q.text.trim(),
          if (type=='multiple_choice') 'options': options.text.split(';').map((e)=>e.trim()).toList(),
          if (type=='multiple_choice') 'answer': answer.text.trim(),
          'order_index': (count as List).length,
        });
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
      }
    }
  }
}

class ItemRef {
  final String id;
  final String kind; // 'lesson' | 'task'
  final int order;
  final String title;
  ItemRef(this.id, this.kind, this.order, this.title);
}

class MixedOrdering extends StatefulWidget {
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> tasks;
  final Future<void> Function(List<ItemRef>) onReorder;
  const MixedOrdering({super.key, required this.lessons, required this.tasks, required this.onReorder});
  @override
  State<MixedOrdering> createState() => _MixedOrderingState();
}

class _MixedOrderingState extends State<MixedOrdering> {
  late List<ItemRef> items;
  @override
  void initState() {
    super.initState();
    items = [
      ...widget.lessons.map((e) => ItemRef(e['id'].toString(), 'lesson', (e['order_index'] as int?) ?? 0, (e['title'] ?? 'Урок') as String)),
      ...widget.tasks.map((e) => ItemRef(e['id'].toString(), 'task', (e['order_index'] as int?) ?? 0, (e['question'] ?? 'Задание') as String)),
    ]..sort((a, b) => a.order.compareTo(b.order));
  }
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final it = items.removeAt(oldIndex);
        items.insert(newIndex, it);
        setState(() {});
        await widget.onReorder(items.asMap().entries.map((e) => ItemRef(e.value.id, e.value.kind, e.key, e.value.title)).toList());
      },
      children: [
        for (final i in items)
          ListTile(
            key: ValueKey('${i.kind}:${i.id}'),
            leading: Icon(i.kind == 'lesson' ? Icons.menu_book : Icons.task_alt),
            title: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.drag_handle),
          ),
      ],
    );
  }
}
