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
  List<int> stepMap = [];
  Map<int, int> unitToStep = {};
  int step = 0;
  Set<int> done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = SupabaseManager.client;
    final cid = widget.course.id;
    final sections = await sb
        .from('course_sections')
        .select('id,title,description,order_index')
        .eq('course_id', cid)
        .order('order_index');

    final list = <_Unit>[];
    for (final s in sections) {
      list.add(_Unit('section', s['title'] ?? 'Раздел', s['description'] ?? '', meta: {'id': s['id']}));

      List subs = [];
      try {
        subs = await sb
            .from('course_subsections')
            .select('id,title,order_index')
            .eq('section_id', s['id'])
            .order('order_index');
      } catch (_) {
        subs = [];
      }

      if (subs.isNotEmpty) {
        for (final ss in subs) {
          list.add(_Unit('subsection', ss['title'] ?? 'Подраздел', '', meta: {'id': ss['id']}));
          final lessons = await sb
              .from('section_lessons')
              .select('id,title,content,order_index')
              .eq('subsection_id', ss['id'])
              .order('order_index');
          for (final l in lessons) {
            list.add(_Unit('lesson', l['title'] ?? 'Урок', l['content'] ?? '', meta: {'id': l['id']}));
          }
          final tasks = await sb
              .from('course_tasks')
              .select('id,type,question,code_template,options,answer,order_index')
              .eq('subsection_id', ss['id'])
              .order('order_index');
          for (final t in tasks) {
            list.add(_Unit('task:${t['type']}', t['question'] ?? 'Задание', t['code_template'] ?? '', meta: t));
          }
        }
      } else {
        final lessons = await sb
            .from('section_lessons')
            .select('id,title,content,order_index')
            .eq('section_id', s['id'])
            .order('order_index');
        for (final l in lessons) {
          list.add(_Unit('lesson', l['title'] ?? 'Урок', l['content'] ?? '', meta: {'id': l['id']}));
        }
        final tasks = await sb
            .from('course_tasks')
            .select('id,type,question,code_template,options,answer,order_index')
            .eq('section_id', s['id'])
            .order('order_index');
        for (final t in tasks) {
          list.add(_Unit('task:${t['type']}', t['question'] ?? 'Задание', t['code_template'] ?? '', meta: t));
        }
      }
    }

    // Build step map (only lessons/tasks are steps)
    final steps = <int>[];
    final unitToStepLocal = <int, int>{};
    for (var i = 0; i < list.length; i++) {
      final k = list[i].kind;
      if (k == 'lesson' || k.startsWith('task:')) {
        unitToStepLocal[i] = steps.length;
        steps.add(i);
      }
    }

    // Load completion
    final uid = sb.auth.currentUser?.id;
    final localDone = <int>{};
    if (uid != null) {
      try {
        final subs = await sb.from('task_submissions').select('task_id,is_correct').eq('user_id', uid);
        for (var i = 0; i < list.length; i++) {
          final u = list[i];
          if (u.kind.startsWith('task:')) {
            final tid = u.meta?['id'];
            final row = (subs as List).cast<Map<String, dynamic>>().firstWhere(
              (e) => e['task_id'] == tid && (e['is_correct'] == true || e['is_correct'] == null),
              orElse: () => {},
            );
            if (row.isNotEmpty && (row['is_correct'] == true)) {
              final sIdx = unitToStepLocal[i];
              if (sIdx != null) localDone.add(sIdx);
            }
          }
        }
      } catch (_) {}
      try {
        final reads = await sb.from('lesson_reads').select('lesson_id').eq('user_id', uid);
        for (var i = 0; i < list.length; i++) {
          final u = list[i];
          if (u.kind == 'lesson') {
            final lid = u.meta?['id'];
            if ((reads as List).any((e) => e['lesson_id'] == lid)) {
              final sIdx = unitToStepLocal[i];
              if (sIdx != null) localDone.add(sIdx);
            }
          }
        }
      } catch (_) {}
    }

    setState(() {
      units = list;
      stepMap = steps;
      unitToStep = unitToStepLocal;
      done = localDone;
      step = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = stepMap.length;
    final u = (step < total) ? units[stepMap[step]] : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: total == 0
          ? const Center(child: CircularProgressIndicator())
          : Row(children: [
              Container(
                width: 280,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _buildSidebar(),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(children: [
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final active = i == step;
                        final completed = done.contains(i);
                        return InkWell(
                          onTap: () => setState(() => step = i),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: completed ? Colors.green : (active ? Colors.blueGrey : Colors.grey),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: total,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _UnitView(
                        unit: u!,
                        onComplete: () async {
                          done.add(step);
                          setState(() {});
                          final unit = units[stepMap[step]];
                          final sb = SupabaseManager.client;
                          final uid = sb.auth.currentUser?.id;
                          if (uid != null && unit.kind == 'lesson') {
                            try {
                              await sb.from('lesson_reads').insert({'lesson_id': unit.meta?['id'], 'user_id': uid});
                            } catch (_) {}
                          }
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: step > 0 ? () => setState(() => step--) : null, child: const Text('Назад')),
                      Text('${step + 1} / $total'),
                      FilledButton(onPressed: step < total - 1 ? () => setState(() => step++) : null, child: const Text('Далее')),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ]),
    );
  }

  List<Widget> _buildSidebar() {
    final items = <Widget>[];
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (u.kind == 'section') {
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(u.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ));
      } else if (u.kind == 'subsection') {
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 12, 2),
          child: Text(u.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ));
      } else {
        final sIdx = unitToStep[i] ?? -1;
        final isActive = sIdx == step;
        items.add(ListTile(
          dense: true,
          selected: isActive,
          leading: Icon(u.kind.startsWith('task') ? Icons.task_alt : Icons.menu_book, size: 18),
          title: Text(u.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: sIdx >= 0 && done.contains(sIdx)
              ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
              : null,
          onTap: () { if (sIdx >= 0) setState(() => step = sIdx); },
        ));
      }
    }
    return items;
  }
}

class _Unit {
  final String kind; // section, subsection, lesson, task:*
  final String title;
  final String content;
  final Map<String, dynamic>? meta; // include ids
  _Unit(this.kind, this.title, this.content, {this.meta});
}

class _UnitView extends StatelessWidget {
  final _Unit unit;
  final VoidCallback onComplete;
  const _UnitView({required this.unit, required this.onComplete});
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
          Wrap(
            spacing: 8,
            children: opts
                .map((o) => OutlinedButton(
                      onPressed: () {
                        final ok = o == right;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(ok ? 'Верно!' : 'Неверно')));
                        if (ok) onComplete();
                      },
                      child: Text(o),
                    ))
                .toList(),
          )
        ]);
      }
      if (type == 'code') {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(unit.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('Откройте детальный режим для запуска кода.'),
        ]);
      }
      return Text(unit.title);
    }
    // lesson text
    WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
    return SingleChildScrollView(child: Text('${unit.title}\n\n${unit.content}'));
  }
}

