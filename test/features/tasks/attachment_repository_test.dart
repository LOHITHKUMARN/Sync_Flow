import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/data/attachment_repository.dart';
import 'package:sync_flow/features/tasks/domain/attachment_model.dart';

void main() {
  group('Phase 7: Attachment Repository & Storage Tests', () {
    late MockAttachmentRepository repo;

    setUp(() {
      repo = MockAttachmentRepository();
    });

    test('Loads initial seeded attachments for task', () async {
      final attachments = await repo.getAttachments('t-1');
      expect(attachments.isNotEmpty, isTrue);
      expect(attachments.length, 2);
      expect(attachments.first.fileName, 'aura_dark_palette.png');
      expect(attachments.first.isImage, isTrue);
    });

    test('Adds new attachment and updates stream', () async {
      final newAttachment = TaskAttachment(
        id: 'att-test-1',
        taskId: 't-1',
        fileName: 'wireframe.png',
        fileUrl: 'https://example.com/wireframe.png',
        fileSizeBytes: 2048000,
        fileType: 'image/png',
        uploadedBy: 'Alex Rivera',
        createdAt: DateTime.now(),
      );

      final created = await repo.addAttachment(newAttachment);
      expect(created.id, isNotEmpty);
      expect(created.fileName, 'wireframe.png');

      final updatedList = await repo.getAttachments('t-1');
      expect(updatedList.length, 3);
      expect(updatedList.any((a) => a.fileName == 'wireframe.png'), isTrue);
    });

    test('Deletes attachment properly', () async {
      final initial = await repo.getAttachments('t-1');
      expect(initial.length, 2);

      await repo.deleteAttachment('att-1');

      final remaining = await repo.getAttachments('t-1');
      expect(remaining.length, 1);
      expect(remaining.any((a) => a.id == 'att-1'), isFalse);
    });

    test('Attachment format size and image type detection', () {
      final img = TaskAttachment(
        id: '1',
        taskId: 't-1',
        fileName: 'photo.JPG',
        fileUrl: 'https://...',
        fileSizeBytes: 2621440, // 2.5 MB
        createdAt: DateTime.now(),
      );
      expect(img.isImage, isTrue);
      expect(img.formattedSize, '2.5 MB');

      final doc = TaskAttachment(
        id: '2',
        taskId: 't-1',
        fileName: 'notes.pdf',
        fileUrl: 'https://...',
        fileSizeBytes: 51200, // 50 KB
        createdAt: DateTime.now(),
      );
      expect(doc.isImage, isFalse);
      expect(doc.formattedSize, '50.0 KB');
    });
  });
}
