import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Уведомления',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NotificationsScreen(),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Демонстрационные данные для списка уведомлений
    final List<NotificationItem> notifications = [
      NotificationItem(
        avatar: 'assets/avatar.png',
        username: 'user100500',
        action: 'оценил запись',
        content: '“Новая методика упражнений”',
        date: '01.01.2024',
        type: NotificationType.evaluation,
      ),
      // Добавьте дополнительные уведомления здесь...
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Уведомления'),
      ),
      
      body: ListView.builder(
        
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return NotificationCard(notification: notifications[index]);
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          // Загрузите и используйте правильный ресурс вместо `Icons.person`
          child: Icon(Icons.person),
          backgroundColor: Colors.green,
        ),
        title: Text(notification.username),
        subtitle: Text('${notification.action} “${notification.content}” от ${notification.date}'),
        trailing: notification.type == NotificationType.evaluation
            ? Icon(Icons.thumb_up, color: Colors.green)
            : Icon(Icons.comment, color: Colors.blue),
      ),
    );
  }
}

class NotificationItem {
  String avatar;
  String username;
  String action;
  String content;
  String date;
  NotificationType type;

  NotificationItem({
    required this.avatar,
    required this.username,
    required this.action,
    required this.content,
    required this.date,
    required this.type,
  });
}

enum NotificationType { evaluation, comment }
