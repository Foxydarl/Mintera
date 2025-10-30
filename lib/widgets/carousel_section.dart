import 'package:flutter/material.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';
import '../pages/course_detail_page.dart';

class CarouselSection extends StatefulWidget {
  final String title;
  final List<Course> items;
  const CarouselSection({super.key, required this.title, required this.items});

  @override
  State<CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<CarouselSection> {
  final controller = ScrollController();

  void _scrollBy(double delta) {
    final next = controller.offset + delta;
    controller.animateTo(next.clamp(0, controller.position.maxScrollExtent), duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = 260.0;
    final spacing = 16.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withOpacity(0.2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              SizedBox(
                height: 270,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 10),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) => SizedBox(
                          width: cardWidth,
                          child: CourseCard(
                            course: widget.items[i],
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => _CourseDetailRouter(course: widget.items[i]),
                              ));
                            },
                          ),
                        ),
                        separatorBuilder: (_, __) => SizedBox(width: spacing),
                        itemCount: widget.items.length,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ArrowButton(icon: Icons.arrow_back, onTap: () => _scrollBy(-width * 0.6)),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ArrowButton(icon: Icons.arrow_forward, onTap: () => _scrollBy(width * 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon),
            ),
          ),
        ),
      ),
    );
  }
}

// Simple local router to avoid direct import cycles
class _CourseDetailRouter extends StatelessWidget {
  final Course course;
  const _CourseDetailRouter({required this.course});
  @override
  Widget build(BuildContext context) {
    // Import at runtime by referencing the page type
    return _CourseDetailScaffoldProxy(course: course);
  }
}

class _CourseDetailScaffoldProxy extends StatelessWidget {
  final Course course;
  const _CourseDetailScaffoldProxy({required this.course});
  @override
  Widget build(BuildContext context) {
    return CourseDetailPage(course: course);
  }
}
