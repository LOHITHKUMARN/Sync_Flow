import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/comment_repository.dart';
import '../domain/comment_model.dart';
import '../../../core/config/env_config.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseCommentRepository(sb.Supabase.instance.client);
  }
  return MockCommentRepository();
});

class TaskCommentsNotifier extends Notifier<AsyncValue<List<TaskComment>>> {
  final String taskId;

  TaskCommentsNotifier(this.taskId);

  @override
  AsyncValue<List<TaskComment>> build() {
    final repo = ref.watch(commentRepositoryProvider);
    final sub = repo.watchComments(taskId).listen(
      (comments) => state = AsyncValue.data(comments),
      onError: (_, __) {},
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadComments);
    return const AsyncValue.loading();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(commentRepositoryProvider);
      final list = await repo.getComments(taskId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TaskComment> postComment({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    String? replyToId,
  }) async {
    final repo = ref.read(commentRepositoryProvider);
    final comment = TaskComment(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );

    final created = await repo.addComment(comment);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, created]);
    return created;
  }

  Future<void> deleteComment(String commentId) async {
    final repo = ref.read(commentRepositoryProvider);
    await repo.deleteComment(commentId: commentId, taskId: taskId);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((c) => c.id != commentId && c.replyToId != commentId).toList(),
    );
  }
}

final taskCommentsProvider = NotifierProvider.family<
    TaskCommentsNotifier, AsyncValue<List<TaskComment>>, String>(
  (arg) => TaskCommentsNotifier(arg),
);
