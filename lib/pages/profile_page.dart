import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../utils/error_messages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final service = ProfileService();
  final name = TextEditingController();
  final email = TextEditingController();
  final bio = TextEditingController();
  final pass = TextEditingController();
  bool loading = true;
  String? error;
  final storage = StorageService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await service.fetchProfile();
      name.text = (data?['username'] as String?) ?? '';
      bio.text = (data?['bio'] as String?) ?? '';
      email.text = service.ready ? (service.sb.auth.currentUser?.email ?? '') : '';
    } catch (e) {
      error = humanizeAuthError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final url = await storage.pickAndUpload(bucket: 'avatars', pathPrefix: 'avatars');
                              if (url != null) {
                                await service.updateProfile(avatarUrl: url);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аватар обновлён')));
                              }
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
                            }
                          },
                          icon: const Icon(Icons.upload),
                          label: const Text('Загрузить аватар'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextField(controller: name, decoration: const InputDecoration(labelText: 'Имя пользователя')),
                      const SizedBox(height: 12),
                      TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')), 
                      const SizedBox(height: 12),
                      TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Биография')),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await service.updateProfile(username: name.text.trim(), bio: bio.text.trim());
                            await service.updateEmail(email.text.trim());
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
                          }
                        },
                        child: const Text('Сохранить изменения'),
                      ),
                      const Divider(height: 32),
                      const Text('Смена пароля', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Новый пароль')),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          if (pass.text.isEmpty) return;
                          try {
                            await service.updatePassword(pass.text);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль обновлён')));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanizeAuthError(e))));
                          }
                        },
                        child: const Text('Обновить пароль'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
