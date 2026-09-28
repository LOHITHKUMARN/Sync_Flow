import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../../../core/config/env_config.dart';
import '../data/attachment_repository.dart';
import '../domain/attachment_model.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseAttachmentRepository(sb.Supabase.instance.client);
  }
  return MockAttachmentRepository();
});

class TaskAttachmentsNotifier extends Notifier<AsyncValue<List<TaskAttachment>>> {
  final String taskId;

  TaskAttachmentsNotifier(this.taskId);

  @override
  AsyncValue<List<TaskAttachment>> build() {
    final repo = ref.watch(attachmentRepositoryProvider);
    final sub = repo.watchAttachments(taskId).listen(
      (attachments) {
        state = AsyncValue.data(attachments);
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadAttachments);
    return const AsyncValue.loading();
  }

  Future<void> loadAttachments() async {
    try {
      final repo = ref.read(attachmentRepositoryProvider);
      final list = await repo.getAttachments(taskId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAttachment({
    required String fileName,
    required String fileUrl,
    int fileSizeBytes = 0,
    String fileType = 'file',
    String? uploadedBy,
  }) async {
    final repo = ref.read(attachmentRepositoryProvider);
    final attachment = TaskAttachment(
      id: const Uuid().v4(),
      taskId: taskId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      fileType: fileType,
      uploadedBy: uploadedBy,
      createdAt: DateTime.now(),
    );

    final created = await repo.addAttachment(attachment);
    final current = state.value ?? [];
    state = AsyncValue.data([created, ...current]);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final repo = ref.read(attachmentRepositoryProvider);
    await repo.deleteAttachment(attachmentId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((a) => a.id != attachmentId).toList());
  }
}

final taskAttachmentsProvider =
    NotifierProvider.family<TaskAttachmentsNotifier, AsyncValue<List<TaskAttachment>>, String>(
  (arg) => TaskAttachmentsNotifier(arg),
);
