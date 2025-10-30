import 'package:flutter/material.dart';
import '../constants.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onAvatarTap;
  final TextEditingController controller;
  final bool isLoggedIn;
  final String? userName;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignUp;
  final VoidCallback? onSignOut;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onMyCourses;

  const HeaderBar({
    super.key,
    this.onSearch,
    this.onAvatarTap,
    required this.controller,
    this.isLoggedIn = false,
    this.userName,
    this.onSignIn,
    this.onSignUp,
    this.onSignOut,
    this.onProfile,
    this.onSettings,
    this.onMyCourses,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _Logo(),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: controller,
                  onSubmitted: onSearch,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Поиск',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            isLoggedIn
                ? PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    onSelected: (v) {
                      switch (v) {
                        case 'profile':
                          onProfile?.call();
                          break;
                        case 'settings':
                          onSettings?.call();
                          break;
                        case 'mycourses':
                          onMyCourses?.call();
                          break;
                        case 'signout':
                          onSignOut?.call();
                          break;
                      }
                    },
                    child: InkWell(
                      onTap: onAvatarTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(userName ?? 'Профиль'),
                            const SizedBox(width: 10),
                            const CircleAvatar(radius: 8, backgroundColor: AppColors.primaryLight),
                          ],
                        ),
                      ),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'profile', child: Text('Профиль')),
                      PopupMenuItem(value: 'settings', child: Text('Настройки')),
                      PopupMenuItem(value: 'mycourses', child: Text('Мои курсы')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'signout', child: Text('Выйти')),
                    ],
                  )
                : Row(children: [
                    TextButton(onPressed: onSignIn, child: const Text('Войти')),
                    const SizedBox(width: 6),
                    FilledButton.tonal(onPressed: onSignUp, child: const Text('Зарегистрироваться')),
                  ]),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryLight],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: const Center(
            child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'mintera',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
