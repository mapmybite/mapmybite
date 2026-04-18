import 'package:flutter/foundation.dart';

class NotificationData {
  static final ValueNotifier<List<Map<String, String>>> notifications =
  ValueNotifier<List<Map<String, String>>>([]);

  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static void addNotification({
    required String title,
    required String message,
  }) {
    final updated = List<Map<String, String>>.from(notifications.value);

    updated.insert(0, {
      'title': title,
      'message': message,
      'time': DateTime.now().toString(),
      'isRead': 'false',
    });

    notifications.value = updated;
    unreadCount.value = unreadCount.value + 1;
  }

  static void markAllAsRead() {
    final updated = notifications.value.map((item) {
      return {
        ...item,
        'isRead': 'true',
      };
    }).toList();

    notifications.value = updated;
    unreadCount.value = 0;
  }

  static void removeNotificationAt(int index) {
    final updated = List<Map<String, String>>.from(notifications.value);

    if (index < 0 || index >= updated.length) return;

    final removed = updated[index];
    final bool wasUnread = (removed['isRead'] ?? 'false') != 'true';

    updated.removeAt(index);
    notifications.value = updated;

    if (wasUnread && unreadCount.value > 0) {
      unreadCount.value = unreadCount.value - 1;
    }
  }

  static void removeNotificationsWhere({
    String? titleContains,
    String? messageContains,
  }) {
    final updated = List<Map<String, String>>.from(notifications.value);

    int removedUnread = 0;

    updated.removeWhere((item) {
      final title = (item['title'] ?? '').toLowerCase();
      final message = (item['message'] ?? '').toLowerCase();

      final matchesTitle = titleContains == null
          ? false
          : title.contains(titleContains.toLowerCase());

      final matchesMessage = messageContains == null
          ? false
          : message.contains(messageContains.toLowerCase());

      final shouldRemove = matchesTitle || matchesMessage;

      if (shouldRemove && (item['isRead'] ?? 'false') != 'true') {
        removedUnread++;
      }

      return shouldRemove;
    });

    notifications.value = updated;

    final int nextUnread = unreadCount.value - removedUnread;
    unreadCount.value = nextUnread < 0 ? 0 : nextUnread;
  }

  static void clearNotifications() {
    notifications.value = [];
    unreadCount.value = 0;
  }
}