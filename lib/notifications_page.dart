import 'package:flutter/material.dart';
import 'notification_data.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();

    /// Clears the red badge count when bell screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationData.markAllAsRead();
    });
  }

  String _formatTime(String rawTime) {
    if (rawTime.trim().isEmpty) return '';

    final DateTime? parsed = DateTime.tryParse(rawTime);
    if (parsed == null) return rawTime;

    final int month = parsed.month;
    final int day = parsed.day;
    final int year = parsed.year;

    int hour = parsed.hour;
    final int minute = parsed.minute;
    final String suffix = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final String minuteText = minute.toString().padLeft(2, '0');

    return '$month/$day/$year  $hour:$minuteText $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: NotificationData.notifications,
      builder: (context, notifications, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            centerTitle: true,
            actions: [
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    NotificationData.clearNotifications();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications cleared')),
                    );
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(fontSize: 16),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final title = item['title'] ?? '';
              final message = item['message'] ?? '';
              final time = item['time'] ?? '';

              return Dismissible(
                key: ValueKey('$title-$time-$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) {
                  NotificationData.removeNotificationAt(index);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, 3),
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(time),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}