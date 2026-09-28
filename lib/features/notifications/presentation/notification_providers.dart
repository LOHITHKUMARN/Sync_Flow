import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/config/env_config.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseNotificationRepository(sb.Supabase.instance.client);
  }
  return MockNotificationRepository();
});

class NotificationsNotifier extends Notifier<AsyncValue<List<NotificationItem>>> {
  final String userId;

  NotificationsNotifier(this.userId);

  @override
  AsyncValue<List<NotificationItem>> build() {
    final repo = ref.watch(notificationRepositoryProvider);
    final sub = repo.watchNotifications(userId).listen(
      (items) => state = AsyncValue.data(items),
      onError: (_, __) {},
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadNotifications);
    return const AsyncValue.loading();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final list = await repo.getNotifications(userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(notificationId);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAsUnread(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsUnread(notificationId);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == notificationId ? n.copyWith(isRead: false) : n).toList(),
    );
  }

  Future<void> toggleReadStatus(String notificationId) async {
    final current = state.value ?? [];
    final item = current.firstWhere((n) => n.id == notificationId, orElse: () => current.first);
    if (item.isRead) {
      await markAsUnread(notificationId);
    } else {
      await markAsRead(notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(userId);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> dismiss(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteNotification(notificationId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((n) => n.id != notificationId).toList());
  }

  Future<void> restore(NotificationItem item) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.restoreNotification(item);
    final current = state.value ?? [];
    final exists = current.any((n) => n.id == item.id);
    if (!exists) {
      final updated = [item, ...current]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(updated);
    }
  }

  Future<void> sendNotification({
    required String recipientUserId,
    required String actorId,
    required String actorName,
    String? actorAvatar,
    required NotificationType type,
    required String title,
    required String body,
    String? taskId,
    String? projectId,
    String? workspaceId,
  }) async {
    final repo = ref.read(notificationRepositoryProvider);
    final notif = NotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: recipientUserId,
      actorId: actorId,
      actorName: actorName,
      actorAvatar: actorAvatar,
      type: type,
      title: title,
      body: body,
      taskId: taskId,
      projectId: projectId,
      workspaceId: workspaceId,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await repo.createNotification(notif);
    if (recipientUserId == userId) {
      final current = state.value ?? [];
      state = AsyncValue.data([notif, ...current]);
    }
  }
}

final notificationsProvider = NotifierProvider.family<
    NotificationsNotifier, AsyncValue<List<NotificationItem>>, String>(
  (arg) => NotificationsNotifier(arg),
);

final unreadNotificationsCountProvider = Provider.family<int, String>((ref, userId) {
  final notifsAsync = ref.watch(notificationsProvider(userId));
  return notifsAsync.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final activeUserNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'demo-user-001';
  final notifsAsync = ref.watch(notificationsProvider(userId));
  return notifsAsync.value ?? [];
});
