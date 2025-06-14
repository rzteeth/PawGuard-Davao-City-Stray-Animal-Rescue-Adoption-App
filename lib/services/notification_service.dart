import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // "adoption" or "rescue"
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'status': 'approved', // Always approved
        'timestamp': Timestamp.now(),
        'read': false, // Default: unread
      });
      print('Notification added successfully!');
    } catch (e) {
      print('Error adding notification: $e');
    }
  }
}
