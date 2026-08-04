import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const pushDeviceToken = String.fromEnvironment('PUSH_DEVICE_TOKEN');
  static const pushPlatform = String.fromEnvironment('PUSH_PLATFORM', defaultValue: 'android');

  static bool get hasSupabaseConfig => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

abstract final class AppBootstrap {
  static SupabaseClient? client;
  static bool demoMode = true;

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      demoMode = true;
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    client = Supabase.instance.client;
    demoMode = false;
  }
}
