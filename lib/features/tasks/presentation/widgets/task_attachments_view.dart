import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/attachment_model.dart';
import '../attachment_providers.dart';

class TaskAttachmentsView extends ConsumerStatefulWidget {
  final String taskId;

  const TaskAttachmentsView({super.key, required this.taskId});

  @override
  ConsumerState<TaskAttachmentsView> createState() => _TaskAttachmentsViewState();
}

class _TaskAttachmentsViewState extends ConsumerState<TaskAttachmentsView> {
  void _showAddAttachmentDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'image/png';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.attach_file_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Attachment',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'File Name',
                  hintText: 'e.g. system_architecture.png',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'File URL / Link',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quick Presets:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  ActionChip(
                    label: const Text('UI Mockup', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        nameController.text = 'ui_mockup_v2.png';
                        urlController.text = 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=800';
                        selectedType = 'image/png';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Design Spec (PDF)', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        nameController.text = 'product_spec.pdf';
                        urlController.text = 'https://example.com/spec.pdf';
                        selectedType = 'application/pdf';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Flow Diagram', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        nameController.text = 'flow_diagram.png';
                        urlController.text = 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800';
                        selectedType = 'image/png';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (name.isNotEmpty && url.isNotEmpty) {
                  final currentUser = ref.read(currentUserProvider);
                  ref.read(taskAttachmentsProvider(widget.taskId).notifier).addAttachment(
                        fileName: name,
                        fileUrl: url,
                        fileSizeBytes: selectedType == 'application/pdf' ? 3200000 : 1800000,
                        fileType: selectedType,
                        uploadedBy: currentUser?.fullName ?? 'Team Member',
                      );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Attach File'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(widget.taskId));

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              attachmentsAsync.maybeWhen(
                data: (list) => Text(
                  '${list.length} ${list.length == 1 ? 'attachment' : 'attachments'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAttachmentDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.border, height: 1),

        // Grid / List View
        Expanded(
          child: attachmentsAsync.when(
            data: (attachments) {
              if (attachments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attachment_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      const Text(
                        'No attachments yet',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Attach design specs, wireframes, and documents.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _showAddAttachmentDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add First Attachment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: attachments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = attachments[index];
                  return _buildAttachmentCard(context, item);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading attachments: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(BuildContext context, TaskAttachment item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Preview thumbnail / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.surface,
              child: item.isImage
                  ? Image.network(
                      item.fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    )
                  : Icon(
                      item.fileType.contains('pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_rounded,
                      color: item.fileType.contains('pdf') ? AppColors.error : AppColors.primaryLight,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      item.formattedSize,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    if (item.uploadedBy != null) ...[
                      const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text(
                        item.uploadedBy!,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                    const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      DateFormat('MMM d').format(item.createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
            tooltip: 'Delete attachment',
            onPressed: () {
              ref.read(taskAttachmentsProvider(widget.taskId).notifier).deleteAttachment(item.id);
            },
          ),
        ],
      ),
    );
  }
}
