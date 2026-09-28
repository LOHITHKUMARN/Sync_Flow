import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../tasks/domain/task_model.dart';
import '../../../tasks/presentation/task_providers.dart';
import '../../../tasks/presentation/widgets/task_detail_sheet.dart';
import '../../domain/notification_model.dart';
import '../notification_providers.dart';

enum NotificationFilter {
  all('All'),
  unread('Unread'),
  assigned('Assigned'),
  comments('Comments'),
  dueSoon('Due soon');

  final String label;
  const NotificationFilter(this.label);
}

class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  @override
  ConsumerState<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends ConsumerState<NotificationCenterSheet> {
  NotificationFilter _activeFilter = NotificationFilter.all;

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationType.commentAdded:
        return Icons.chat_bubble_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
      case NotificationType.dueDateSoon:
        return Icons.alarm_rounded;
      case NotificationType.workspaceInvite:
        return Icons.group_add_rounded;
    }
  }

  Color _badgeColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return const Color(0xFF3B82F6); // Electric Blue
      case NotificationType.commentAdded:
        return const Color(0xFF8B5CF6); // Cyber Violet
      case NotificationType.mention:
        return const Color(0xFF06B6D4); // Neon Cyan
      case NotificationType.dueDateSoon:
        return const Color(0xFFF59E0B); // Amber Warning
      case NotificationType.workspaceInvite:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    switch (_activeFilter) {
      case NotificationFilter.all:
        return items;
      case NotificationFilter.unread:
        return items.where((n) => !n.isRead).toList();
      case NotificationFilter.assigned:
        return items.where((n) => n.type == NotificationType.taskAssigned).toList();
      case NotificationFilter.comments:
        return items
            .where((n) =>
                n.type == NotificationType.commentAdded || n.type == NotificationType.mention)
            .toList();
      case NotificationFilter.dueSoon:
        return items.where((n) => n.type == NotificationType.dueDateSoon).toList();
    }
  }

  Future<void> _handleNotificationTap(
      NotificationItem notif, String userId, BuildContext context) async {
    // Mark as read immediately
    if (!notif.isRead) {
      ref.read(notificationsProvider(userId).notifier).markAsRead(notif.id);
    }

    // Deep link to task if present
    if (notif.taskId != null && notif.projectId != null) {
      try {
        final tasks = await ref.read(taskRepositoryProvider).getTasks(notif.projectId!);
        TaskItem? targetTask;
        for (final t in tasks) {
          if (t.id == notif.taskId) {
            targetTask = t;
            break;
          }
        }

        if (targetTask != null && context.mounted) {
          Navigator.of(context).pop(); // Close notification sheet
          TaskDetailSheet.show(context, targetTask, notif.projectId);
          return;
        }
      } catch (_) {
        // Fallback gracefully
      }
    }
  }

  Widget _buildRichBody(NotificationItem notif, bool isDark) {
    final textColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
    final boldColor = isDark ? Colors.white : const Color(0xFF09090B);

    final rawText = notif.body;

    // Parse quotes for highlighting task names / comment snippets
    final quoteParts = rawText.split('"');
    if (quoteParts.length >= 3) {
      final beforeQuote = quoteParts[0];
      final insideQuote = quoteParts[1];
      final afterQuote = quoteParts.sublist(2).join('"');

      final spans = <InlineSpan>[];

      // Check if actor name is at start of beforeQuote
      if (notif.actorName.isNotEmpty && beforeQuote.startsWith(notif.actorName)) {
        spans.add(TextSpan(
          text: notif.actorName,
          style: TextStyle(fontWeight: FontWeight.w700, color: boldColor),
        ));
        spans.add(TextSpan(text: beforeQuote.substring(notif.actorName.length)));
      } else {
        spans.add(TextSpan(text: beforeQuote));
      }

      // Quoted text (Task title or comment preview)
      spans.add(TextSpan(
        text: '"$insideQuote"',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: boldColor,
          fontStyle: notif.type == NotificationType.commentAdded ? FontStyle.italic : FontStyle.normal,
        ),
      ));

      if (afterQuote.isNotEmpty) {
        spans.add(TextSpan(text: afterQuote));
      }

      return Text.rich(
        TextSpan(children: spans),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: textColor,
          height: 1.35,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Default rich styling with bold actor name if present
    if (notif.actorName.isNotEmpty && rawText.startsWith(notif.actorName)) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: notif.actorName,
              style: TextStyle(fontWeight: FontWeight.w700, color: boldColor),
            ),
            TextSpan(text: rawText.substring(notif.actorName.length)),
          ],
        ),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: textColor,
          height: 1.35,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      rawText,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: textColor,
        height: 1.35,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAvatar(NotificationItem notif, Color badgeColor, bool isDark) {
    // 3. Due-date card: dedicated system alert avatar
    if (notif.type == NotificationType.dueDateSoon) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withAlpha(35),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFF59E0B).withAlpha(90),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.alarm_rounded,
            size: 20,
            color: Color(0xFFF59E0B),
          ),
        ),
      );
    }

    // User avatar with type badge overlay
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: badgeColor.withAlpha(30),
          backgroundImage:
              notif.actorAvatar != null ? NetworkImage(notif.actorAvatar!) : null,
          onBackgroundImageError: notif.actorAvatar != null ? (_, __) {} : null,
          child: notif.actorAvatar == null
              ? Text(
                  notif.actorName.isNotEmpty
                      ? notif.actorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF141416) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              _iconForType(notif.type),
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required NotificationItem notif,
    required String userId,
    required bool isDark,
  }) {
    final badgeColor = _badgeColorForType(notif.type);
    final isDueSoon = notif.type == NotificationType.dueDateSoon;

    final cardBg = notif.isRead
        ? (isDark ? const Color(0xFF101012) : const Color(0xFFF9F9FA))
        : (isDark ? const Color(0xFF17171A) : Colors.white);

    final cardBorder = notif.isRead
        ? (isDark ? const Color(0xFF232328) : const Color(0xFFE4E4E7))
        : (isDark ? badgeColor.withAlpha(70) : badgeColor.withAlpha(90));

    final titleColor = isDark ? Colors.white : const Color(0xFF09090B);

    return Dismissible(
      key: ValueKey('notif-${notif.id}'),
      direction: DismissDirection.horizontal,
      // Swipe Right -> Mark Read / Unread
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              notif.isRead ? Icons.mark_email_unread_rounded : Icons.done_rounded,
              color: const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              notif.isRead ? 'Mark unread' : 'Mark read',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
      // Swipe Left -> Dismiss with Undo option
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.priorityUrgent.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismiss',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.priorityUrgent,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.priorityUrgent,
              size: 20,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle read/unread without removing from tree
          ref.read(notificationsProvider(userId).notifier).toggleReadStatus(notif.id);
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        ref.read(notificationsProvider(userId).notifier).dismiss(notif.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification dismissed',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                ref.read(notificationsProvider(userId).notifier).restore(notif);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      child: Semantics(
        label:
            '${notif.isRead ? "Read" : "Unread"}. ${notif.title}, ${notif.body}, ${isDueSoon ? "Due in 24 hours" : _formatRelativeTime(notif.createdAt)}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(notif, userId, context),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cardBorder,
                  width: notif.isRead ? 1.0 : 1.5,
                ),
                boxShadow: notif.isRead
                    ? null
                    : [
                        BoxShadow(
                          color: badgeColor.withAlpha(isDark ? 20 : 15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left unread accent indicator stripe for unread items
                  if (!notif.isRead) ...[
                    Container(
                      width: 3.5,
                      height: 38,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],

                  // Avatar / System icon
                  _buildAvatar(notif, badgeColor, isDark),
                  const SizedBox(width: 12),

                  // Notification Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight:
                                      notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 4. Deadline timestamp vs Relative time
                            if (isDueSoon)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Due in 24h',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                _formatRelativeTime(notif.createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFFA1A1AA)
                                      : const Color(0xFF71717A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // 5. Rich parsed body with bold important words
                        _buildRichBody(notif, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Unread Dot & Chevron indicator for tap feedback
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!notif.isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withAlpha(120),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232328) : const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isFiltering = _activeFilter != NotificationFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF4F4F5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                ),
              ),
              child: Icon(
                isFiltering
                    ? Icons.filter_alt_off_rounded
                    : Icons.check_circle_outline_rounded,
                size: 32,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering ? 'No matching notifications' : "You're all caught up",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF09090B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltering
                  ? 'No notifications found for this filter tab.'
                  : 'Check back later for updates, mentions, and due date alerts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                height: 1.4,
              ),
            ),
            if (isFiltering) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => setState(() => _activeFilter = NotificationFilter.all),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Show all notifications'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? 'demo-user-001';

    final notifsAsync = ref.watch(notificationsProvider(userId));
    final allNotifs = notifsAsync.value ?? [];
    final unreadCount = allNotifs.where((n) => !n.isRead).length;

    final filteredNotifs = _applyFilter(allNotifs);

    // 6. Time Grouping: Today vs Earlier
    final todayList = filteredNotifs.where((n) => _isToday(n.createdAt)).toList();
    final earlierList = filteredNotifs.where((n) => !_isToday(n.createdAt)).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header: Title, Unread Pill & Mark All Read
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Notifications',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(notificationsProvider(userId).notifier).markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 15),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      tooltip: 'Notification preferences',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Real-time live push sync is active.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 10. Horizontal Scrolling Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: NotificationFilter.values.map((filter) {
                  final isSelected = _activeFilter == filter;
                  final isUnreadChip = filter == NotificationFilter.unread;
                  final isDimmed = isUnreadChip && unreadCount == 0;

                  String chipLabel = filter.label;
                  if (isUnreadChip) {
                    chipLabel = 'Unread ($unreadCount)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Opacity(
                      opacity: isDimmed ? 0.45 : 1.0,
                      child: FilterChip(
                        label: Text(chipLabel),
                        selected: isSelected,
                        selectedColor:
                            Theme.of(context).colorScheme.primary.withAlpha(40),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF09090B))
                              : (isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A)),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withAlpha(120)
                              : (isDark
                                  ? const Color(0xFF26262B)
                                  : const Color(0xFFE4E4E7)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _activeFilter = filter);
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Divider(
              color: isDark ? const Color(0xFF26262B) : const Color(0xFFE4E4E7),
              height: 1,
            ),
            const SizedBox(height: 6),

            // Notification List View with Time Grouping
            Expanded(
              child: filteredNotifs.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (todayList.isNotEmpty) ...[
                          _buildSectionHeader('Today', todayList.length, isDark),
                          ...todayList.map((notif) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildNotificationCard(
                                  notif: notif,
                                  userId: userId,
                                  isDark: isDark,
                                ),
                              )),
                        ],
                        if (earlierList.isNotEmpty) ...[
                          _buildSectionHeader('Earlier', earlierList.length, isDark),
                          ...earlierList.map((notif) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildNotificationCard(
                                  notif: notif,
                                  userId: userId,
                                  isDark: isDark,
                                ),
                              )),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
