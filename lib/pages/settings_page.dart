import 'package:flutter/material.dart';
import '../theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final mode = ThemeController.instance.mode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Тема', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode)),
                  ButtonSegment(value: ThemeMode.system, label: Text('Системная'), icon: Icon(Icons.settings_brightness)),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ThemeController.instance.setMode(s.first),
              ),
              const SizedBox(height: 24),
              const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Показывать советы и новости'),
                value: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Уведомлять об ответах на комментарии'),
                value: true,
                onChanged: (_) {},
              ),
            ],
          );
        },
      ),
    );
  }
}
