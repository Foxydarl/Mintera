import 'package:flutter/material.dart';
import '../supabase_manager.dart';
import '../models/course.dart';

class CourseRunPage extends StatefulWidget {
  final Course course;
  const CourseRunPage({super.key, required this.course});
  @override
  State<CourseRunPage> createState() => _CourseRunPageState();
}

class _CourseRunPageState extends State<CourseRunPage> {
  List<_Unit> units = [];
  int index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = SupabaseManager.client;
    final cid = widget.course.id;
    final sections = await sb.from('course_sections').select('id,title,description,order_index').eq('course_id', cid).order('order_index');
    final list = <_Unit>[];
    for (final s in sections) {
      list.add(_Unit('section', s['title'] ?? 'Раздел', s['description'] ?? ''));
      final lessons = await sb.from('section_lessons').select('title,content,order_index').eq('section_id', s['id']).order('order_index');
      for (final l in lessons) {
        list.add(_Unit('lesson', l['title'] ?? 'Урок', l['content'] ?? ''));
      }
      final tasks = await sb.from('course_tasks').select('type,question,code_template,options,answer,order_index').eq('section_id', s['id']).order('order_index');
      for (final t in tasks) {
        list.add(_Unit('task:${t['type']}', t['question'] ?? 'Задание', t['code_template'] ?? '', meta: t));
      }
    }
    setState(() => units = list);
  }

  @override
  Widget build(BuildContext context) {
    final total = units.length;
    final u = index < units.length ? units[index] : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: total == 0
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // progress dots
              SizedBox(
                height: 30,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final active = i == index;
                    return Container(width: 10, height: 10, decoration: BoxDecoration(color: active ? Colors.green : Colors.grey, shape: BoxShape.circle));
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: total,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _UnitView(unit: u!),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: index > 0 ? () => setState(() => index--) : null, child: const Text('Назад')),
                  Text('${index + 1} / $total'),
                  FilledButton(onPressed: index < total - 1 ? () => setState(() => index++) : null, child: const Text('Далее')),
                ],
              ),
              const SizedBox(height: 8),
            ]),
    );
  }
}

class _Unit {
  final String kind; // section, lesson, task:*
  final String title;
  final String content;
  final Map<String, dynamic>? meta;
  _Unit(this.kind, this.title, this.content, {this.meta});
}

class _UnitView extends StatelessWidget {
  final _Unit unit;
  const _UnitView({required this.unit});
  @override
  Widget build(BuildContext context) {
    if (unit.kind.startsWith('task:')) {
      final type = unit.kind.substring(5);
      if (type == 'multiple_choice') {
        final opts = List<String>.from(unit.meta?['options'] ?? []);
        final right = (unit.meta?['answer'] ?? '').toString();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(unit.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: opts.map((o)=>OutlinedButton(onPressed: (){
            final ok = o == right;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok? 'Верно!' : 'Неверно')));
          }, child: Text(o))).toList())
        ]);
      }
      if (type == 'code') {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(unit.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // For brevity: show plain text for template (runner already exists in details page)
          Text('Откройте детальный режим для запуска кода.'),
        ]);
      }
      return Text(unit.title);
    }
    // section/lesson simple text
    return SingleChildScrollView(child: Text(unit.title + '\n\n' + unit.content));
  }
}

