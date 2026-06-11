import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../viewmodels/application/notification_viewmodel.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationNotificationViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationViewModel = context
        .watch<ApplicationNotificationViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(notificationViewModel),
    );
  }

  Widget _buildBody(ApplicationNotificationViewModel notificationViewModel) {
    if (notificationViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationViewModel.errorMessage != null) {
      return Center(child: Text(notificationViewModel.errorMessage!));
    }

    if (notificationViewModel.notifications.isEmpty) {
      return const Center(child: Text("No notifications available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificationViewModel.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationViewModel.notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () {
        context.read<ApplicationNotificationViewModel>().markAsRead(
          notification.notificationID,
        );
        _showNotificationDetails(notification);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: notification.isRead ? Colors.white : Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                notification.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat("dd MMM yyyy").format(notification.createdTime),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            notification.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(notification.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
