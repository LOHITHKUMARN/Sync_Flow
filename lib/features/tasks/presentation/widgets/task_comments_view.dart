import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../notifications/domain/notification_model.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../domain/comment_model.dart';
import '../comment_providers.dart';

class TaskCommentsView extends ConsumerStatefulWidget {
  final String taskId;
  final String projectId;

  const TaskCommentsView({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  @override
  ConsumerState<TaskCommentsView> createState() => _TaskCommentsViewState();
}

class _TaskCommentsViewState extends ConsumerState<TaskCommentsView> {
  final _commentController = TextEditingController();
  TaskComment? _replyingTo;
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _handlePostComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    final authorId = currentUser?.id ?? 'demo-user-001';
    final authorName = currentUser?.fullName ?? 'Alex Rivera';
    final authorAvatar = currentUser?.avatarUrl;

    setState(() => _isPosting = true);

    try {
      await ref.read(taskCommentsProvider(widget.taskId).notifier).postComment(
            authorId: authorId,
            authorName: authorName,
            authorAvatar: authorAvatar,
            content: text,
            replyToId: _replyingTo?.id,
          );

      if (_replyingTo != null && _replyingTo!.authorId != authorId) {
        ref.read(notificationsProvider(_replyingTo!.authorId).notifier).sendNotification(
              recipientUserId: _replyingTo!.authorId,
              actorId: authorId,
              actorName: authorName,
              actorAvatar: authorAvatar,
              type: NotificationType.commentAdded,
              title: 'Reply on Task',
              body: '$authorName replied: "$text"',
              taskId: widget.taskId,
              projectId: widget.projectId,
            );
      }

      _commentController.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));
    final comments = commentsAsync.value ?? [];

    // Group comments into root comments and their replies
    final rootComments = comments.where((c) => c.replyToId == null).toList();
    final replies = comments.where((c) => c.replyToId != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comments.isEmpty && !commentsAsync.isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 36,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No comments yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start a conversation with your team members.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rootComments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = rootComments[index];
              final threadReplies = replies.where((r) => r.replyToId == comment.id).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentCard(comment, isDark),
                  if (threadReplies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 8),
                      child: Column(
                        children: threadReplies.map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildCommentCard(r, isDark, isReply: true),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),

        // Replying to banner
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF09090B)),
                    const SizedBox(width: 6),
                    Text(
                      'Replying to ${_replyingTo!.authorName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _replyingTo = null),
                  child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF09090B)),
                ),
              ],
            ),
          ),

        // Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? 'Write a reply...'
                        : 'Write a comment or mention @team...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isPosting ? null : _handlePostComment,
                icon: _isPosting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.send_rounded, color: isDark ? Colors.white : const Color(0xFF09090B), size: 20),
                tooltip: 'Send Comment',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(TaskComment comment, bool isDark, {bool isReply = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? (isReply ? AppColors.darkBg : AppColors.darkSurface)
            : (isReply ? AppColors.lightBg : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: isReply ? 0.7 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Relative time, Reply & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                    backgroundImage: comment.authorAvatar != null
                        ? NetworkImage(comment.authorAvatar!)
                        : null,
                    child: comment.authorAvatar == null
                        ? Text(
                            comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.authorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRelativeTime(comment.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _replyingTo = comment;
                      });
                    },
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    tooltip: 'Reply',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(taskCommentsProvider(widget.taskId).notifier)
                          .deleteComment(comment.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Content
          Text(
            comment.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
