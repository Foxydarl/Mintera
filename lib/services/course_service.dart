import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../constants.dart';
import '../supabase_manager.dart';

class CourseService {
  final _rng = Random(42);

  Future<List<Course>> fetchCourses({String? category, String? query}) async {
    try {
      if (SupabaseManager.initialized) {
        final sb = SupabaseManager.client;
        var builder = sb.from('courses').select();
        if (category != null && category.isNotEmpty) {
          builder = builder.eq('category', category);
        }
        if (query != null && query.isNotEmpty) {
          builder = builder.ilike('title', '%$query%');
        }
        final data = await builder.order('created_at', ascending: false).limit(24);
        return data.map<Course>((e) => Course.fromMap(e)).toList();
      }
    } catch (_) {}
    return _mockCourses(category: category, query: query);
  }

  List<Course> _mockCourses({String? category, String? query}) {
    final cats = ['Онлайн-курсы', AppCategories.it, AppCategories.languages, AppCategories.modeling, AppCategories.other];
    final c = category ?? cats[0];
    final base = List.generate(8, (i) {
      return Course(
        id: 'mock-$c-$i',
        title: 'Тестовый курс',
        description: 'Допустим тестовое описание, lorem ipsum и т.д. и т.п.',
        author: 'Автор Алексеевич',
        price: 1600,
        imageUrl: '',
        views: _rng.nextInt(500) + 100,
        likes: _rng.nextInt(200) + 20,
        rating: 3.5 + _rng.nextDouble() * 1.5,
        category: c,
      );
    });
    final q = query?.toLowerCase();
    if (q == null || q.isEmpty) return base;
    return base.where((e) => e.title.toLowerCase().contains(q)).toList();
  }
}
