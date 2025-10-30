import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class SupabaseManager {
  static bool _initialized = false;

  static bool get initialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (_initialized || !AppConfig.hasSupabase) return;
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    _initialized = true;
  }
}

