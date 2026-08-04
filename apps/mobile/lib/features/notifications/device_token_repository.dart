import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class DeviceTokenRepository {
  Future<void> register({required String token, required String platform});

  Future<void> unregister({required String token});
}

class FakeDeviceTokenRepository implements DeviceTokenRepository {
  FakeDeviceTokenRepository({Map<String, String>? initialTokens})
      : _tokens = {...?initialTokens};

  final Map<String, String> _tokens;

  Map<String, String> get registeredTokens => Map.unmodifiable(_tokens);

  @override
  Future<void> register({required String token, required String platform}) async {
    _validate(token: token, platform: platform);
    _tokens[token.trim()] = platform.trim().toLowerCase();
  }

  @override
  Future<void> unregister({required String token}) async {
    _tokens.remove(token.trim());
  }

  static void _validate({required String token, required String platform}) {
    if (token.trim().isEmpty) throw ArgumentError('A device token is required.');
    const platforms = {'android', 'ios', 'web'};
    if (!platforms.contains(platform.trim().toLowerCase())) {
      throw ArgumentError('Unsupported device platform.');
    }
  }
}

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  SupabaseDeviceTokenRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> register({required String token, required String platform}) async {
    await client.rpc('register_device_token', params: {
      'p_token': token.trim(),
      'p_platform': platform.trim().toLowerCase(),
    });
  }

  @override
  Future<void> unregister({required String token}) async {
    await client.rpc('unregister_device_token', params: {
      'p_token': token.trim(),
    });
  }
}
