import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // Import the NotificationService

class AdoptionService {
  static Future<void> approveAdoptionApplication(
      String userId, String petName, String applicationId) async {
    try {
      // Update application status in Firestore
      await FirebaseFirestore.instance
          .collection('adoptionApplications')
          .doc(applicationId) // Use the specific application ID
          .update({'status': 'approved'});

      // Add a notification for the user
      NotificationService.addNotification(
        userId: userId,
        title: 'Adoption Approved!',
        message: 'Congratulations! Your application to adopt $petName has been approved.',
        type: 'adoption',
      );

      print('Adoption application approved!');
    } catch (e) {
      print('Error approving adoption application: $e');
    }
  }
}
