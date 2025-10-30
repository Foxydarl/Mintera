import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/course.dart';
import '../supabase_manager.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              image: course.imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(course.imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: course.imageUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.school, size: 40, color: AppColors.primary),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Text(course.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (course.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Builder(builder: (context) {
              String authorLabel = (course.author).toString();
              try {
                final uid = SupabaseManager.initialized ? SupabaseManager.client.auth.currentUser?.id : null;
                if (course.owner != null && uid != null && course.owner == uid) {
                  authorLabel = 'Вы';
                } else {
                  // Не показываем "Вы" для чужих курсов или когда пользователь не авторизован
                  final lower = authorLabel.trim().toLowerCase();
                  if (lower == 'вы' || lower == 'you') {
                    authorLabel = 'Автор';
                  }
                }
              } catch (_) {}
              return Text('Автор $authorLabel', style: const TextStyle(fontSize: 12));
            }),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text('${course.views}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 10),
                const Icon(Icons.favorite_border, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text('${course.likes}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 10),
                const Icon(Icons.star_rate_rounded, size: 16, color: Colors.amber),
                Text(course.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const Spacer(),
                Text('${course.price} ₽', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          )
        ],
      ),
    ));
  }
}
