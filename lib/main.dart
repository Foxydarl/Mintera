import 'package:flutter/material.dart';
import 'constants.dart';
import 'pages/home_page.dart';
import 'supabase_manager.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();
  runApp(const MinteraApp());
}

class MinteraApp extends StatelessWidget {
  const MinteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mintera',
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeController.instance.mode,
          debugShowCheckedModeBanner: false,
          routes: {
            '/': (_) => const HomePage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}
