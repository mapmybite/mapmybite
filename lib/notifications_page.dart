import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_text.dart';
import 'notification_data.dart';
import 'orders_page.dart';
import 'customer_order_history_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterTts _notificationTts = FlutterTts();
  String _speakingNotificationId = '';
  bool _isSpeakingNotification = false;

  @override
  void initState() {
    super.initState();

    /// Clears the red badge count when bell screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationData.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _notificationTts.stop();
    super.dispose();
  }

  Future<void> _setupVoice() async {
    switch (AppText.language) {
      case 'es':
        await _notificationTts.setLanguage('es-ES');
        break;
      case 'hi':
        await _notificationTts.setLanguage('hi-IN');
        break;
      case 'pa':
        await _notificationTts.setLanguage('pa-IN');
        break;
      default:
        await _notificationTts.setLanguage('en-US');
    }

    await _notificationTts.setSpeechRate(0.43);
    await _notificationTts.setPitch(1.08);
    await _notificationTts.setVolume(1.0);
  }

  Future<void> _toggleSpeakNotification({
    required String notificationId,
    required String title,
    required String message,
    required String time,
  }) async {
    final text = _buildNotificationSpeech(
      title: title,
      message: message,
      time: time,
    ).trim();

    if (text.isEmpty) return;

    await _setupVoice();

    if (_isSpeakingNotification &&
        _speakingNotificationId == notificationId) {
      await _notificationTts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeakingNotification = false;
        _speakingNotificationId = '';
      });

      return;
    }

    await _notificationTts.stop();

    if (!mounted) return;

    setState(() {
      _isSpeakingNotification = true;
      _speakingNotificationId = notificationId;
    });

    await _notificationTts.speak(text);

    _notificationTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeakingNotification = false;
        _speakingNotificationId = '';
      });
    });

    _notificationTts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeakingNotification = false;
        _speakingNotificationId = '';
      });
    });
  }

  String _txt(String key) {
    switch (AppText.language) {
      case 'es':
        return {
          'notifications': 'Notificaciones',
          'clearAll': 'Borrar todo',
          'cleared': 'Todas las notificaciones borradas',
          'none': 'No hay notificaciones todavía',
          'deleted': 'Notificación eliminada',
          'readNotification': 'Leer notificación',
          'notification': 'Notificación',
          'message': 'Mensaje',
          'time': 'Hora',
        }[key] ??
            key;
      case 'hi':
        return {
          'notifications': 'सूचनाएं',
          'clearAll': 'सभी साफ करें',
          'cleared': 'सभी सूचनाएं साफ कर दी गईं',
          'none': 'अभी कोई सूचना नहीं है',
          'deleted': 'सूचना हटा दी गई',
          'readNotification': 'सूचना सुनें',
          'notification': 'सूचना',
          'message': 'संदेश',
          'time': 'समय',
        }[key] ??
            key;
      case 'pa':
        return {
          'notifications': 'ਸੂਚਨਾਵਾਂ',
          'clearAll': 'ਸਭ ਸਾਫ਼ ਕਰੋ',
          'cleared': 'ਸਾਰੀਆਂ ਸੂਚਨਾਵਾਂ ਸਾਫ਼ ਕਰ ਦਿੱਤੀਆਂ',
          'none': 'ਹਾਲੇ ਕੋਈ ਸੂਚਨਾ ਨਹੀਂ',
          'deleted': 'ਸੂਚਨਾ ਹਟਾ ਦਿੱਤੀ ਗਈ',
          'readNotification': 'ਸੂਚਨਾ ਸੁਣੋ',
          'notification': 'ਸੂਚਨਾ',
          'message': 'ਸੁਨੇਹਾ',
          'time': 'ਸਮਾਂ',
        }[key] ??
            key;
      default:
        return {
          'notifications': 'Notifications',
          'clearAll': 'Clear All',
          'cleared': 'All notifications cleared',
          'none': 'No notifications yet',
          'deleted': 'Notification deleted',
          'readNotification': 'Read notification',
          'notification': 'Notification',
          'message': 'Message',
          'time': 'Time',
        }[key] ??
            key;
    }
  }
  void _openNotificationDestination(String title, String message) {
    final text = '$title $message'.toLowerCase();

    if (text.contains('new order')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersPage()),
      );
      return;
    }

    if (text.contains('order') || text.contains('payment')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerOrderHistoryPage()),
      );
      return;
    }
  }

  String _buildNotificationSpeech({
    required String title,
    required String message,
    required String time,
  }) {
    final formattedTime = _formatTime(time);
    final cleanTitle =
        title.trim().isEmpty ? _txt('notification') : title.trim();
    final cleanMessage = message.trim();

    switch (AppText.language) {
      case 'es':
        return '$cleanTitle. ${_txt('message')}: $cleanMessage. ${_txt('time')}: $formattedTime.';
      case 'hi':
        return '$cleanTitle। ${_txt('message')}: $cleanMessage। ${_txt('time')}: $formattedTime।';
      case 'pa':
        return '$cleanTitle। ${_txt('message')}: $cleanMessage। ${_txt('time')}: $formattedTime।';
      default:
        return '$cleanTitle. ${_txt('message')}: $cleanMessage. ${_txt('time')}: $formattedTime.';
    }
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
            title: Text(_txt('notifications')),
            centerTitle: true,
            actions: [
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    NotificationData.clearNotifications();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_txt('cleared'))),
                    );
                  },
                  child: Text(_txt('clearAll')),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Text(
                    _txt('none'),
                    style: const TextStyle(fontSize: 16),
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
                    final notificationId = '$title-$time-$index';
                    final isThisSpeaking = _isSpeakingNotification &&
                        _speakingNotificationId == notificationId;

                    return Dismissible(
                      key: ValueKey(notificationId),
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
                          SnackBar(
                            content: Text(_txt('deleted')),
                          ),
                        );
                      },
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openNotificationDestination(title, message),
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
                                    title.trim().isEmpty
                                        ? _txt('notification')
                                        : title,
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
                            IconButton(
                              tooltip: _txt('readNotification'),
                              onPressed: () => _toggleSpeakNotification(
                                notificationId: notificationId,
                                title: title,
                                message: message,
                                time: time,
                              ),
                              icon: Icon(
                                isThisSpeaking
                                    ? Icons.stop_circle
                                    : Icons.volume_up,
                                color: Colors.orange,
                              ),
                            ),
                                                    ],
                                                  ),
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
