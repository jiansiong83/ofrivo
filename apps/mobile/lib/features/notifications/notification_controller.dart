import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/data/fake_data.dart';
import '../../core/models/app_models.dart';
import '../auth/auth_controller.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    return FakeNotificationRepository(fakeNotifications);
  }
  return SupabaseNotificationRepository(client, auth.user!.id);
});

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final controller =
      NotificationController(ref.watch(notificationRepositoryProvider));
  controller.load();
  return controller;
});

class NotificationState {
  const NotificationState(
      {this.initialized = false,
      this.isLoading = false,
      this.notifications = const [],
      this.error});

  final bool initialized;
  final bool isLoading;
  final List<AppNotification> notifications;
  final String? error;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  NotificationState copyWith(
          {bool? initialized,
          bool? isLoading,
          List<AppNotification>? notifications,
          String? error,
          bool clearError = false}) =>
      NotificationState(
        initialized: initialized ?? this.initialized,
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        error: clearError ? null : error ?? this.error,
      );
}

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this.repository) : super(const NotificationState());

  final NotificationRepository repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await repository.loadNotifications();
      state =
          NotificationState(initialized: true, notifications: notifications);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to load notifications. Check your connection.');
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await repository.markRead(notificationId);
      state = state.copyWith(notifications: [
        for (final item in state.notifications)
          item.id == notificationId ? item.copyWith(isRead: true) : item
      ]);
    } catch (_) {
      state = state.copyWith(error: 'Unable to update this notification.');
    }
  }

  Future<void> markAllRead() async {
    try {
      await repository.markAllRead();
      state = state.copyWith(notifications: [
        for (final item in state.notifications) item.copyWith(isRead: true),
      ]);
    } catch (_) {
      state = state.copyWith(error: 'Unable to update notifications.');
    }
  }
}
