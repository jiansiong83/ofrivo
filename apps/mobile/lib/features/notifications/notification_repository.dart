import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/app_models.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> loadNotifications();

  Future<void> markRead(String notificationId);
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository(this._notifications);

  final List<AppNotification> _notifications;

  @override
  Future<List<AppNotification>> loadNotifications() async {
    final items = List<AppNotification>.from(_notifications)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List<AppNotification>.unmodifiable(items);
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications
        .indexWhere((notification) => notification.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<AppNotification>> loadNotifications() async {
    final rows = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<AppNotification>.unmodifiable(
        (rows as List).whereType<Map<String, dynamic>>().map(_map));
  }

  @override
  Future<void> markRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  AppNotification _map(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as String,
        type: _type(row['type'] as String?),
        title: row['title'] as String? ?? 'Notification',
        body: row['body'] as String? ?? '',
        isRead: row['is_read'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        referenceType: row['reference_type'] as String?,
        referenceId: row['reference_id'] as String?,
      );

  NotificationType _type(String? value) {
    switch (value) {
      case 'new_bid':
        return NotificationType.newBid;
      case 'bid_accepted':
        return NotificationType.bidAccepted;
      case 'job_assigned':
        return NotificationType.jobAssigned;
      case 'provider_approved':
        return NotificationType.providerApproved;
      case 'job_started':
        return NotificationType.jobStarted;
      case 'job_completed':
        return NotificationType.jobCompleted;
      case 'job_cancelled':
        return NotificationType.jobCancelled;
      default:
        return NotificationType.generic;
    }
  }
}
