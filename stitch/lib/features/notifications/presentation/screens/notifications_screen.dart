/// Notifications screen displaying actual activities from the database.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/sidad_empty_state.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final readAt = ref.watch(notificationsReadAtProvider);

    // Ensure read timestamp is loaded
    ref.watch(notificationsReadAtLoaderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationControllerProvider.notifier).markAllRead();
            },
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'خطأ في تحميل الإشعارات: $err',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const SidadEmptyState(
              icon: Icons.notifications_none_rounded,
              title: AppStrings.noNotifications,
              description: AppStrings.noNotificationsDesc,
            );
          }

          final sections = _groupNotifications(notifications);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sections.length,
            itemBuilder: (context, si) {
              final section = sections[si];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (si > 0) const SizedBox(height: 24),
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...section.items.map((n) {
                    final isUnread = readAt == null
                        ? true
                        : n.createdAt.isAfter(readAt);
                    final iconData = _getIcon(n.icon);
                    final color = _getColor(n.color);
                    final timeAgo = _formatTimeAgo(n.createdAt);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SidadCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(iconData, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 16),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String iconStr) {
    switch (iconStr) {
      case 'person_add':
        return Icons.person_add_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'cancel':
        return Icons.cancel_rounded;
      case 'notifications':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String colorStr) {
    switch (colorStr) {
      case 'info':
        return AppColors.info;
      case 'success':
        return AppColors.success;
      case 'error':
        return AppColors.error;
      case 'primary':
      default:
        return AppColors.primary;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else {
      return intl.DateFormat('dd/MM/yyyy HH:mm', 'ar').format(dt);
    }
  }

  List<_Section> _groupNotifications(List<NotificationModel> list) {
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final older = <NotificationModel>[];

    final now = DateTime.now();

    for (var n in list) {
      final dt = n.createdAt.toLocal();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        today.add(n);
      } else {
        final yesterdayDt = now.subtract(const Duration(days: 1));
        if (dt.year == yesterdayDt.year &&
            dt.month == yesterdayDt.month &&
            dt.day == yesterdayDt.day) {
          yesterday.add(n);
        } else {
          older.add(n);
        }
      }
    }

    final sections = <_Section>[];
    if (today.isNotEmpty) sections.add(_Section('اليوم', today));
    if (yesterday.isNotEmpty) sections.add(_Section('أمس', yesterday));
    if (older.isNotEmpty) sections.add(_Section('أقدم', older));

    return sections;
  }
}

class _Section {
  final String title;
  final List<NotificationModel> items;
  const _Section(this.title, this.items);
}
