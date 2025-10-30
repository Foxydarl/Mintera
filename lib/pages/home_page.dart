import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../widgets/carousel_section.dart';
import '../widgets/header_bar.dart';
import '../services/auth_service.dart';
import '../utils/error_messages.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'my_courses_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = CourseService();
  final _search = TextEditingController();
  final _auth = AuthService();
  List<Course> _online = const [];
  List<Course> _it = const [];
  List<Course> _lang = const [];
  List<Course> _model = const [];
  List<Course> _other = const [];
  bool _loading = true;
  bool _loggedIn = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _load();
    if (_auth.isReady) {
      _loggedIn = _auth.currentUser != null;
      _userName = _auth.userName;
      _auth.onAuthStateChange().listen((event) {
        if (mounted) {
          setState(() {
            _loggedIn = _auth.currentUser != null;
            _userName = _auth.userName;
          });
        }
      });
    }
  }

  Future<void> _load([String q = '']) async {
    setState(() => _loading = true);
    final online = await _service.fetchCourses(category: 'Онлайн-курсы', query: q);
    final it = await _service.fetchCourses(category: AppCategories.it, query: q);
    final lang = await _service.fetchCourses(category: AppCategories.languages, query: q);
    final model = await _service.fetchCourses(category: AppCategories.modeling, query: q);
    final other = await _service.fetchCourses(category: AppCategories.other, query: q);
    if (mounted) {
      setState(() {
        _online = online;
        _it = it;
        _lang = lang;
        _model = model;
        _other = other;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: HeaderBar(
        onSearch: _load,
        controller: _search,
        isLoggedIn: _loggedIn,
        userName: _userName,
        onSignOut: () async {
          await _auth.signOut();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы вышли из аккаунта')));
        },
        onSignIn: () => _showAuthSheet(context, isSignUp: false),
        onSignUp: () => _showAuthSheet(context, isSignUp: true),
        onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
        onSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        onMyCourses: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyCoursesPage())),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      CarouselSection(title: 'Онлайн-курсы', items: _online),
                      const SizedBox(height: 10),
                      CarouselSection(title: AppCategories.it, items: _it),
                      const SizedBox(height: 10),
                      CarouselSection(title: AppCategories.languages, items: _lang),
                      const SizedBox(height: 10),
                      CarouselSection(title: AppCategories.modeling, items: _model),
                      const SizedBox(height: 10),
                      CarouselSection(title: AppCategories.other, items: _other),
                    ],
                  ),
                ),
              ),
            ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }

  void _showAuthSheet(BuildContext context, {required bool isSignUp}) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        bool loading = false;
        String? errorText;
        return StatefulBuilder(builder: (context, setSt) {
          Future<void> handleError(Object e) async {
            setSt(() => errorText = humanizeAuthError(e));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSignUp ? 'Регистрация' : 'Вход', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (!_auth.isReady)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      'Supabase не сконфигурирован. Запустите приложение с --dart-define=SUPABASE_URL и --dart-define=SUPABASE_ANON_KEY.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                if (!_auth.isReady) const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
                if (isSignUp) ...[
                  const SizedBox(height: 10),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Имя пользователя (необязательно)')),
                ],
                const SizedBox(height: 12),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                Row(
                  children: [
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              final pass = passCtrl.text;
                              if (email.isEmpty || pass.isEmpty) return;
                              try {
                                setSt(() => loading = true);
                                if (isSignUp) {
                                  await _auth.signUpWithPassword(email, pass, username: nameCtrl.text.trim());
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Регистрация выполнена. При необходимости подтвердите email.')));
                                  }
                                } else {
                                  final res = await _auth.signInWithPassword(email, pass);
                                  if (mounted && res != null) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы вошли в аккаунт')));
                                  }
                                }
                              } catch (e) {
                                await handleError(e);
                              } finally {
                                setSt(() => loading = false);
                              }
                            },
                      child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isSignUp ? 'Зарегистрироваться' : 'Войти'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty) return;
                              try {
                                setSt(() => loading = true);
                                await _auth.signInWithEmailOtp(email);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Magic link отправлен на email')));
                                }
                              } catch (e) {
                                await handleError(e);
                              } finally {
                                setSt(() => loading = false);
                              }
                            },
                      child: const Text('Войти по ссылке'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Подсказка: включите Email provider в Supabase. При включённом подтверждении email — вход возможен после подтверждения.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }
}
