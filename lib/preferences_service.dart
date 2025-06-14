// preferences_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  PreferencesService({required this.userId});

  Future<void> savePreferences(List<String> preferences) async {
    await _firestore.collection('users').doc(userId).update({
      'preferences': preferences,
    });
  }

  Future<List<String>> getPreferences() async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(doc.data()?['preferences'] ?? []);
  }
}
