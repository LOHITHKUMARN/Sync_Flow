import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/notifications/data/notification_repository.dart';
import 'package:sync_flow/features/notifications/domain/notification_model.dart';

void main() {
  group('MockNotificationRepository Tests', () {
    late MockNotificationRepository repo;

    setUp(() {
      repo = MockNotificationRepository();
    });

    test('Loads initial seeded notifications for demo user', () async {
      final notifs = await repo.getNotifications('demo-user-001');
      expect(notifs.length, 5);
      expect(notifs.any((n) => n.type == NotificationType.taskAssigned), true);
      expect(notifs.any((n) => n.type == NotificationType.commentAdded), true);
      expect(notifs.any((n) => n.type == NotificationType.dueDateSoon), true);
    });

    test('Marks single notification as read and unread', () async {
      final initial = await repo.getNotifications('demo-user-001');
      final unread = initial.firstWhere((n) => !n.isRead);

      await repo.markAsRead(unread.id);
      var updated = await repo.getNotifications('demo-user-001');
      var item = updated.firstWhere((n) => n.id == unread.id);
      expect(item.isRead, true);

      await repo.markAsUnread(unread.id);
      updated = await repo.getNotifications('demo-user-001');
      item = updated.firstWhere((n) => n.id == unread.id);
      expect(item.isRead, false);
    });

    test('Marks all notifications as read', () async {
      await repo.markAllAsRead('demo-user-001');
      final list = await repo.getNotifications('demo-user-001');
      expect(list.every((n) => n.isRead), true);
    });

    test('Dispatches new notification to recipient stream', () async {
      final newNotif = NotificationItem(
        id: 'test-notif-1',
        userId: 'demo-user-001',
        actorId: 'demo-user-002',
        actorName: 'Rahul Sharma',
        type: NotificationType.taskAssigned,
        title: 'New Architecture Task',
        body: 'Assigned to Offline Sync Engine.',
        createdAt: DateTime.now(),
      );

      final created = await repo.createNotification(newNotif);
      expect(created.id, 'test-notif-1');

      final list = await repo.getNotifications('demo-user-001');
      expect(list.any((n) => n.id == 'test-notif-1'), true);
      expect(list.first.id, 'test-notif-1'); // Most recent first
    });

    test('Dismisses and restores notification for undo action', () async {
      final initial = await repo.getNotifications('demo-user-001');
      final itemToDelete = initial.first;

      await repo.deleteNotification(itemToDelete.id);
      var remaining = await repo.getNotifications('demo-user-001');
      expect(remaining.any((n) => n.id == itemToDelete.id), false);

      await repo.restoreNotification(itemToDelete);
      remaining = await repo.getNotifications('demo-user-001');
      expect(remaining.any((n) => n.id == itemToDelete.id), true);
    });
  });
}
