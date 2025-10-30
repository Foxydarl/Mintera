import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_manager.dart';

class ProfileService {
  final sb = Supabase.instance.client;

  bool get ready => SupabaseManager.initialized && sb.auth.currentUser != null;

  Future<Map<String, dynamic>?> fetchProfile() async {
    if (!ready) return null;
    final uid = sb.auth.currentUser!.id;
    final res = await sb.from('profiles').select().eq('id', uid).maybeSingle();
    return res;
  }

  Future<void> updateProfile({String? username, String? bio, String? avatarUrl}) async {
    if (!ready) return;
    final uid = sb.auth.currentUser!.id;
    try {
      await sb.from('profiles').upsert({
        'id': uid,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
      });
    } catch (_) {
      // fallback without bio if column missing
      await sb.from('profiles').upsert({
        'id': uid,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      if (bio != null) {
        try { await sb.from('profiles').update({'bio': bio}).eq('id', uid); } catch (_) {}
      }
    }
  }

  Future<void> updateEmail(String email) async {
    if (!ready) return;
    await sb.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> updatePassword(String password) async {
    if (!ready) return;
    await sb.auth.updateUser(UserAttributes(password: password));
  }
}
