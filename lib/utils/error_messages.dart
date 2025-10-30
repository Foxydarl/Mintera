import 'package:supabase_flutter/supabase_flutter.dart';

String humanizeAuthError(Object error) {
  // Default
  final raw = error.toString();
  // Try typed auth exceptions first
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('password should be at least') || msg.contains('weak password')) {
      // Extract a number if present
      final match = RegExp(r'(\d+)').firstMatch(error.message);
      final n = match != null ? match.group(1) : '6';
      return 'Пароль слишком слабый. Минимум $n символов.';
    }
    if (msg.contains('invalid login credentials')) {
      return 'Неверный email или пароль.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email не подтверждён. Проверьте почту.';
    }
    if (msg.contains('user already registered')) {
      return 'Пользователь с таким email уже существует.';
    }
    return error.message; // generic from Supabase
  }
  // Fallback simple patterns
  if (raw.contains('422') && raw.toLowerCase().contains('password')) {
    return 'Пароль слишком слабый. Минимум 6 символов.';
  }
  return 'Ошибка: $raw';
}

