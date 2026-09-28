import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../domain/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> getNotifications(String userId);
  Future<NotificationItem> createNotification(NotificationItem item);
  Future<void> markAsRead(String notificationId);
  Future<void> markAsUnread(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<void> restoreNotification(NotificationItem item);
  Stream<List<NotificationItem>> watchNotifications(String userId);
}

class SupabaseNotificationRepository implements NotificationRepository {
  final sb.SupabaseClient _client;

  SupabaseNotificationRepository(this._client);

  @override
  Future<List<NotificationItem>> getNotifications(String userId) async {
    final res = await _client
        .from('notifications')
        .select('*, profiles:actor_id(full_name, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List).map((json) => NotificationItem.fromJson(json)).toList();
  }

  @override
  Future<NotificationItem> createNotification(NotificationItem item) async {
    final json = item.toJson()..remove('id');
    final res = await _client
        .from('notifications')
        .insert(json)
        .select('*, profiles:actor_id(full_name, avatar_url)')
        .single();
    return NotificationItem.fromJson(res);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAsUnread(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': false})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  @override
  Future<void> restoreNotification(NotificationItem item) async {
    await _client.from('notifications').upsert(item.toJson());
  }

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((_) => getNotifications(userId));
  }
}

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _notifications = [];
  final _streamController = StreamController<List<NotificationItem>>.broadcast();

  MockNotificationRepository() {
    _seedNotifications();
  }

  void _seedNotifications() {
    final now = DateTime.now();

    _notifications.addAll([
      NotificationItem(
        id: 'notif-1',
        userId: 'demo-user-001',
        actorId: 'demo-user-002',
        actorName: 'Rahul Sharma',
        actorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        type: NotificationType.taskAssigned,
        title: 'Assigned to you',
        body: 'Rahul assigned you to "Setup WebSocket Realtime Server".',
        taskId: 't-4',
        projectId: 'proj-mobile-app',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      NotificationItem(
        id: 'notif-2',
        userId: 'demo-user-001',
        actorId: 'demo-user-003',
        actorName: 'Ananya Rao',
        actorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        type: NotificationType.commentAdded,
        title: 'New comment on task',
        body: 'Ananya commented: "I added WebSocket ping/pong heartbeat..."',
        taskId: 't-2',
        projectId: 'proj-mobile-app',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: 'notif-3',
        userId: 'demo-user-001',
        actorId: 'system',
        actorName: 'SyncFlow System',
        actorAvatar: null,
        type: NotificationType.dueDateSoon,
        title: 'Due date approaching',
        body: '"Refactor Impeller rendering architecture" is due in 24 hours.',
        taskId: 't-1',
        projectId: 'proj-mobile-app',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationItem(
        id: 'notif-4',
        userId: 'demo-user-001',
        actorId: 'demo-user-002',
        actorName: 'Rahul Sharma',
        actorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        type: NotificationType.mention,
        title: 'Mentioned you in comment',
        body: 'Rahul mentioned you: "@Alex can you review the sprint backlog before standup?"',
        taskId: 't-3',
        projectId: 'proj-mobile-app',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationItem(
        id: 'notif-5',
        userId: 'demo-user-001',
        actorId: 'system',
        actorName: 'SyncFlow System',
        actorAvatar: null,
        type: NotificationType.workspaceInvite,
        title: 'Workspace update',
        body: 'You have been granted Administrator permissions in SyncFlow Flutter Core.',
        taskId: null,
        projectId: 'proj-mobile-app',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Future<List<NotificationItem>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _notifications.where((n) => n.userId == userId || userId.isEmpty).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<NotificationItem> createNotification(NotificationItem item) async {
    await Future.delayed(const Duration(milliseconds: 10));
    _notifications.insert(0, item);
    _streamController.add(List.from(_notifications));
    return item;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _streamController.add(List.from(_notifications));
    }
  }

  @override
  Future<void> markAsUnread(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _streamController.add(List.from(_notifications));
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId || userId.isEmpty) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _streamController.add(List.from(_notifications));
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    _notifications.removeWhere((n) => n.id == notificationId);
    _streamController.add(List.from(_notifications));
  }

  @override
  Future<void> restoreNotification(NotificationItem item) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _notifications.indexWhere((n) => n.id == item.id);
    if (index == -1) {
      _notifications.insert(0, item);
    } else {
      _notifications[index] = item;
    }
    _streamController.add(List.from(_notifications));
  }

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return _streamController.stream.map(
      (list) => list.where((n) => n.userId == userId || userId.isEmpty).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }
}
