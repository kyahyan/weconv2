import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/src/utils/notification_sound_player.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class NotificationScreen extends StatefulWidget {
  final Function(BuildContext context, UserNotification notification)? onNotificationTap;

  const NotificationScreen({super.key, this.onNotificationTap});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notificationRepo = NotificationRepository();
  bool _isLoading = true;
  List<UserNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    
    // Mark all as read when opening screen? Or user manual? 
    // Common pattern is mark all read on open or separate "Mark all read" button.
    // Let's add a button in AppBar action.
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _notificationRepo.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    await _notificationRepo.markAllAsRead();
    _fetchNotifications();
  }
  
  Future<void> _markRead(String id) async {
    await _notificationRepo.markAsRead(id);
    // Optimistically update local state
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      // Highlight unread
                      final isUnread = !notification.isRead;
                      
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          // Optimistic update
                          setState(() {
                            _notifications.removeAt(index);
                          });
                          _notificationRepo.deleteNotification(notification.id).catchError((e) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                               // Should re-fetch or revert if critical, but for notifications just error msg is fine.
                               _fetchNotifications(); 
                             }
                          });
                        },
                        child: Container(
                           color: isUnread ? Colors.blue.withOpacity(0.05) : null,
                           child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isUnread ? Colors.blue : Colors.grey.shade300,
                              child: Icon(
                                _getIconForType(notification.type),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notification.body),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(notification.createdAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            onTap: () {
                              _markRead(notification.id); // Always mark read on tap
                              if (widget.onNotificationTap != null) {
                                widget.onNotificationTap!(context, notification);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_ind;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}

class NotificationBell extends StatefulWidget {
  final Function(BuildContext context, UserNotification notification)? onNotificationTap;

  const NotificationBell({super.key, this.onNotificationTap});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _notificationRepo = NotificationRepository();
  Stream<List<UserNotification>>? _notificationStream;
  int _previousCount = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _notificationStream = _notificationRepo.getNotificationsStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserNotification>>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        // Check for new notifications to show toast/play sound
        if (snapshot.hasData) {
            if (_isFirstLoad) {
               // First load: just set the count, don't notify
               _previousCount = unreadCount;
               _isFirstLoad = false; 
            } else if (unreadCount > _previousCount) {
               // Subsequent updates with MORE unread: Notify
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                     NotificationSoundPlayer.playNotificationSound();
                     // Find the latest one?
                     final latest = notifications.firstOrNull;
                     if (latest != null && !latest.isRead) {
                        ShadToaster.of(context).show(
                          ShadToast(
                            title: Text(latest.title),
                            description: Text(latest.body),
                            action: ShadButton.outline(
                              text: const Text('View'),
                              onPressed: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NotificationScreen(onNotificationTap: widget.onNotificationTap)),
                                );
                              },
                            ),
                          ),
                        );
                     }
                  }
               });
            }
            // Always update previous count
            _previousCount = unreadCount;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen(onNotificationTap: widget.onNotificationTap)),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
