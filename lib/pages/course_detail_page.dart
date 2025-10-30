import 'package:flutter/material.dart';
import '../models/course.dart';
import '../supabase_manager.dart';
import '../utils/error_messages.dart';
import '../widgets/code_runner.dart';
import 'course_run_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  List<Map<String, dynamic>> sections = [];
  bool liked = false;
  double myRating = 0;
  bool loading = true;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sb = SupabaseManager.client;
      final cid = widget.course.id;
      final uid = sb.auth.currentUser?.id;
      final s = await sb.from('course_sections').select('id,title,description,order_index').eq('course_id', cid).order('order_index');
      sections = List<Map<String, dynamic>>.from(s);
      if (uid != null) {
        final fav = await sb.from('favorites').select('liked').eq('course_id', cid).eq('user_id', uid).maybeSingle();
        liked = (fav?['liked'] as bool?) ?? false;
        final r = await sb.from('course_ratings').select('rating').eq('course_id', cid).eq('user_id', uid).maybeSingle();
        myRating = (r?['rating'] as num?)?.toDouble() ?? 0;
      }
      isOwner = (sb.auth.currentUser?.id != null) && (widget.course.owner == sb.auth.currentUser!.id);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _toggleLike() async {
    final sb = SupabaseManager.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Войдите, чтобы лайкать')));
      return;
    }
    try {
      liked = !liked;
      setState(() {});
      await sb.from('favorites').upsert({'user_id': uid, 'course_id': widget.course.id, 'liked': liked});
      await sb.rpc('inc_likes', params: {'cid': widget.course.id, 'delta': liked ? 1 : -1});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
    }
  }

  Future<void> _saveRating(double value) async {
    final sb = SupabaseManager.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => myRating = value);
    try {
      await sb.from('course_ratings').upsert({'user_id': uid, 'course_id': widget.course.id, 'rating': value});
      // Recalculate rating in a simple way (avg)
      await sb.rpc('recalc_course_rating', params: {'cid': widget.course.id});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
    }
  }

  Future<void> _markCompleted() async {
    final sb = SupabaseManager.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await sb.from('enrollments').upsert({'user_id': uid, 'course_id': widget.course.id, 'progress': 100});
      await sb.rpc('inc_views', params: {'cid': widget.course.id});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Курс отмечен как пройден')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
    }
  }

  Future<void> _startCourse() async {
    final sb = SupabaseManager.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Войдите, чтобы начать курс')));
      return;
    }
    try {
      await sb.from('enrollments').upsert({'user_id': uid, 'course_id': widget.course.id, 'progress': 0});
      if (mounted) {
        // перейти в режим прохождения
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseRunPage(course: widget.course)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 240,
                    height: 150,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(12), image: c.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(c.imageUrl), fit: BoxFit.cover) : null),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.description.isNotEmpty ? c.description : 'Описание не заполнено'),
                      const SizedBox(height: 8),
                      Row(children: [
                        IconButton(onPressed: isOwner ? null : _toggleLike, icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.pink : null)),
                        const SizedBox(width: 8),
                        const Text('Оценка:'),
                        Slider(value: myRating, onChanged: isOwner ? null : (v) => _saveRating(v), divisions: 10, min: 0, max: 5, label: myRating.toStringAsFixed(1)),
                        const Spacer(),
                        FilledButton(onPressed: _startCourse, child: const Text('Начать курс')),
                      ]),
                    ]),
                  )
                ]),
                const SizedBox(height: 16),
                const Text('Разделы', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...sections.map((sec) => _SectionTile(section: sec, courseId: widget.course.id)),
              ],
            ),
    );
  }
}

class _SectionTile extends StatefulWidget {
  final Map<String, dynamic> section;
  final String courseId;
  const _SectionTile({required this.section, required this.courseId});
  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  List<Map<String, dynamic>> lessons = [];
  List<Map<String, dynamic>> tasks = [];
  bool expanded = false;

  Future<void> _load() async {
    final sb = SupabaseManager.client;
    final sid = widget.section['id'];
    final l = await sb.from('section_lessons').select().eq('section_id', sid).order('order_index');
    final t = await sb.from('course_tasks').select().eq('section_id', sid).order('order_index');
    if (mounted) setState(() { lessons = List<Map<String,dynamic>>.from(l); tasks = List<Map<String,dynamic>>.from(t); });
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.section['title'] ?? ''),
      subtitle: Text((widget.section['description'] ?? '').toString()),
      onExpansionChanged: (v) { expanded = v; if (v) _load(); },
      children: [
        ...lessons.map((l) => ListTile(title: Text(l['title'] ?? ''), subtitle: Text((l['content'] ?? '').toString()), leading: const Icon(Icons.menu_book))),
        ...tasks.map((t) => ListTile(title: Text(t['question'] ?? ''), leading: const Icon(Icons.task_alt))),
      ],
    );
  }
}

class _TaskTile extends StatefulWidget {
  final Map<String, dynamic> task;
  const _TaskTile({required this.task});
  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  String? chosen;
  bool? correct;

  Future<void> _saveSubmission({String? answer, String? code, bool? isCorrect}) async {
    try {
      final sb = SupabaseManager.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      await sb.from('task_submissions').insert({
        'task_id': widget.task['id'],
        'user_id': uid,
        if (answer != null) 'answer': answer,
        if (code != null) 'code': code,
        if (isCorrect != null) 'is_correct': isCorrect,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final type = task['type'] as String? ?? 'free_text';
    if (type == 'multiple_choice') {
      final opts = List<String>.from(task['options'] ?? []);
      final right = (task['answer'] ?? '').toString();
      return ListTile(
        title: Text(task['question'] ?? ''),
        subtitle: Wrap(
          spacing: 8,
          children: opts.map((o) {
            final isChosen = chosen == o;
            final isCorrect = correct == true && isChosen;
            final isWrong = correct == false && isChosen;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isCorrect
                    ? Colors.green.withOpacity(0.15)
                    : isWrong
                        ? Colors.red.withOpacity(0.15)
                        : null,
              ),
              onPressed: () async {
                final ok = o == right;
                setState(() {
                  chosen = o;
                  correct = ok;
                });
                await _saveSubmission(answer: o, isCorrect: ok);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Верно!' : 'Неверно')),
                );
              },
              child: Text(o),
            );
          }).toList(),
        ),
      );
    }
    if (type == 'code') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          CodeRunner(template: (task['code_template'] ?? '') as String),
        ]),
      );
    }
    return ListTile(
      title: Text(task['question'] ?? ''),
      subtitle: const Text('Ответ в свободной форме'),
    );
  }
}
