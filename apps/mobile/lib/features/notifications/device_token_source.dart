import '../../core/config/app_config.dart';

abstract interface class DeviceTokenSource {
  Future<String?> readToken();

  Stream<String> get tokenRefreshes;
}

class DemoDeviceTokenSource implements DeviceTokenSource {
  const DemoDeviceTokenSource();

  @override
  Future<String?> readToken() async => 'demo-device-token-android';

  @override
  Stream<String> get tokenRefreshes => const Stream<String>.empty();
}

/// Runtime bridge for a native push SDK. The native layer can provide the
/// token through `--dart-define=PUSH_DEVICE_TOKEN=...` until FCM is enabled.
class RuntimeDeviceTokenSource implements DeviceTokenSource {
  const RuntimeDeviceTokenSource();

  @override
  Future<String?> readToken() async {
    final token = AppConfig.pushDeviceToken.trim();
    return token.isEmpty ? null : token;
  }

  @override
  Stream<String> get tokenRefreshes => const Stream<String>.empty();
}
