import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/notifications/notification_repository.dart';

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
  });
}
