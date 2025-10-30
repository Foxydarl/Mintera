import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_manager.dart';

class AuthService {
  final _auth = Supabase.instance.client.auth;

  bool get isReady => SupabaseManager.initialized;

  User? get currentUser => isReady ? _auth.currentUser : null;

  String? get userName => currentUser?.userMetadata?['username'] as String? ?? currentUser?.email;

  Stream<AuthState> onAuthStateChange() => _auth.onAuthStateChange;

  Future<void> signOut() async {
    if (!isReady) return;
    await _auth.signOut();
  }

  Future<void> signInWithEmailOtp(String email, {String? redirectUrl}) async {
    if (!isReady) return;
    final url = redirectUrl ?? (kIsWeb ? Uri.base.origin : null);
    await _auth.signInWithOtp(email: email, emailRedirectTo: url);
  }

  Future<AuthResponse?> signInWithPassword(String email, String password) async {
    if (!isReady) return null;
    final res = await _auth.signInWithPassword(email: email, password: password);
    return res;
  }

  Future<AuthResponse?> signUpWithPassword(String email, String password, {String? username}) async {
    if (!isReady) return null;
    final res = await _auth.signUp(email: email, password: password, data: {
      if (username != null && username.isNotEmpty) 'username': username,
    });
    try {
      final user = res.user;
      if (user != null) {
        // попытка создать/обновить профиль владельца
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          if (username != null && username.isNotEmpty) 'username': username,
        });
      }
    } catch (_) {}
    return res;
  }
}
