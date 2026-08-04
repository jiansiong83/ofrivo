import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/notifications/device_token_repository.dart';
import 'package:ofrivo_mobile/features/notifications/device_token_source.dart';
import 'package:ofrivo_mobile/features/notifications/notification_repository.dart';
import 'package:ofrivo_mobile/features/notifications/push_registration_controller.dart';

void main() {
  test('fake notifications can be loaded and marked as read', () async {
    final notifications = [
      AppNotification(
          id: 'n1',
          type: NotificationType.newBid,
          title: 'New offer',
          body: 'A',
          isRead: false,
          createdAt: DateTime(2026, 8, 4)),
    ];
    final repository = FakeNotificationRepository(notifications);

    expect((await repository.loadNotifications()).single.isRead, isFalse);
    await repository.markRead('n1');
    expect((await repository.loadNotifications()).single.isRead, isTrue);
    await repository.markAllRead();
    expect((await repository.loadNotifications()).single.isRead, isTrue);
  });

  test('device token registration is user-scoped in fake mode', () async {
    final repository = FakeDeviceTokenRepository();
    await repository.register(
        token: 'token-android-001', platform: 'android');
    expect(repository.registeredTokens['token-android-001'], 'android');
    await repository.unregister(token: 'token-android-001');
    expect(repository.registeredTokens, isEmpty);
  });

  test('push registration controller registers the available token', () async {
    final repository = FakeDeviceTokenRepository();
    final controller = PushRegistrationController(
      repository: repository,
      source: const DemoDeviceTokenSource(),
      platform: 'android',
    );

    await controller.register();

    expect(controller.state.tokenRegistered, isTrue);
    expect(repository.registeredTokens['demo-device-token-android'], 'android');
    await controller.unregister();
    expect(controller.state.tokenRegistered, isFalse);
    expect(repository.registeredTokens, isEmpty);
    controller.dispose();
  });
}
