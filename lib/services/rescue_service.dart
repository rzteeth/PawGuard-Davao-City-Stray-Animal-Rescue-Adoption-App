import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // Import the NotificationService

class RescueService {
  static Future<void> approveRescueApplication(
      String userId, String petName, String applicationId) async {
    try {
      // Update application status in Firestore
      await FirebaseFirestore.instance
          .collection('rescueApplications')
          .doc(applicationId) // Use the specific application ID
          .update({'status': 'approved'});

      // Add a notification for the user
      NotificationService.addNotification(
        userId: userId,
        title: 'Rescue Approved!',
        message: 'Great job! Your rescue application for $petName has been approved.',
        type: 'rescue',
      );

      print('Rescue application approved!');
    } catch (e) {
      print('Error approving rescue application: $e');
    }
  }
}
