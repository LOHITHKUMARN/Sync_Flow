import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/data/comment_repository.dart';
import 'package:sync_flow/features/tasks/domain/comment_model.dart';

void main() {
  group('MockCommentRepository Tests', () {
    late MockCommentRepository repo;

    setUp(() {
      repo = MockCommentRepository();
    });

    test('Loads initial seeded comments for task', () async {
      final comments = await repo.getComments('task-auth-001');
      expect(comments.length, 2);
      expect(comments.first.authorName, 'Rahul Sharma');
      expect(comments[1].replyToId, comments.first.id);
    });

    test('Adds root comment and streams update', () async {
      final newComment = TaskComment(
        id: 'test-comment-1',
        taskId: 'task-auth-001',
        authorId: 'user-test',
        authorName: 'Test Contributor',
        content: 'Testing WebSocket subscription resiliency.',
        createdAt: DateTime.now(),
      );

      final created = await repo.addComment(newComment);
      expect(created.id, 'test-comment-1');

      final list = await repo.getComments('task-auth-001');
      expect(list.length, 3);
      expect(list.any((c) => c.content == 'Testing WebSocket subscription resiliency.'), true);
    });

    test('Deletes comment and cascade-removes child replies', () async {
      final initial = await repo.getComments('task-auth-001');
      final parentId = initial.first.id;

      await repo.deleteComment(commentId: parentId, taskId: 'task-auth-001');
      final remaining = await repo.getComments('task-auth-001');

      expect(remaining.any((c) => c.id == parentId), false);
      expect(remaining.any((c) => c.replyToId == parentId), false);
    });
  });
}
