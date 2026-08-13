import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      final result = await repository.getNotifications();
      return result.fold(
        (failure) => throw failure.message,
        (notifications) => notifications,
      );
    });

// Cache notifications_read_at state
final notificationsReadAtProvider = StateProvider<DateTime?>((ref) => null);

// Initializer provider to load it from storage
final notificationsReadAtLoaderProvider = FutureProvider<DateTime?>((
  ref,
) async {
  final secureStorage = ref.read(secureStorageProvider);
  final value = await secureStorage.getNotificationsReadAt();
  if (value != null) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      ref.read(notificationsReadAtProvider.notifier).state = parsed;
      return parsed;
    }
  }
  return null;
});

// Controller to manage notifications state
class NotificationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationController(this._ref) : super(const AsyncData(null));

  Future<void> markAllRead() async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      await _ref
          .read(secureStorageProvider)
          .saveNotificationsReadAt(now.toIso8601String());
      _ref.read(notificationsReadAtProvider.notifier).state = now;
      state = const AsyncData(null);

      // Invalidate notifications to trigger ui refresh
      _ref.invalidate(notificationsProvider);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
      return NotificationController(ref);
    });

// Computed provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final readAt = ref.watch(notificationsReadAtProvider);

  // Trigger loader if not loaded yet
  ref.watch(notificationsReadAtLoaderProvider);

  return notificationsAsync.maybeWhen(
    data: (list) {
      if (readAt == null) {
        return list.length; // If never read, all are unread
      }
      return list.where((n) => n.createdAt.isAfter(readAt)).length;
    },
    orElse: () => 0,
  );
});
