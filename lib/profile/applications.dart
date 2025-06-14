import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({Key? key, required String organizationId}) : super(key: key);

  @override
  _ApplicationsPageState createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String filterStatus = 'all'; // The status filter for the applications

  // Get filtered applications based on the status
  Stream<QuerySnapshot> _getFilteredApplications() {
    CollectionReference applications =
        FirebaseFirestore.instance.collection('adoption_applications');

    if (filterStatus == 'all') {
      return applications
          .orderBy('submissionDate', descending: true)
          .snapshots();
    } else {
      return applications
          .where('status', isEqualTo: filterStatus)
          .orderBy('submissionDate', descending: true)
          .snapshots();
    }
  }

  // Update application status (Approve or Reject)
  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      // Get the current application data to check its existing status
      DocumentSnapshot applicationDoc = await FirebaseFirestore.instance
          .collection('adoption_applications')
          .doc(applicationId)
          .get();

      if (!applicationDoc.exists) {
        throw 'Application not found';
      }

      String currentStatus = applicationDoc['status'] ?? 'pending';

      // If the application is already approved or rejected, prevent further status updates
      if ((currentStatus == 'approved' && newStatus == 'rejected') || 
          (currentStatus == 'rejected' && newStatus == 'approved')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This application status cannot be changed anymore'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update the application status in Firestore
      await FirebaseFirestore.instance
          .collection('adoption_applications')
          .doc(applicationId)
          .update({
        'status': newStatus,
        'lastUpdated': Timestamp.now(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $newStatus successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Adjust the filter to the newly updated status (approve/reject)
      setState(() {
        filterStatus = newStatus;  // Show only the corresponding status
      });

      // If rejected, schedule removal after 3 days
      if (newStatus == 'rejected') {
        _scheduleRemoval(applicationId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update application status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Schedule automatic removal of rejected applications after 3 days
  Future<void> _scheduleRemoval(String applicationId) async {
    Timer(const Duration(days: 3), () async {
      final doc = await FirebaseFirestore.instance
          .collection('adoption_applications')
          .doc(applicationId)
          .get();

      if (doc.exists && doc['status'] == 'rejected') {
        await FirebaseFirestore.instance
            .collection('adoption_applications')
            .doc(applicationId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rejected application removed after 3 days'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    });
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteDialog(String applicationId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await FirebaseFirestore.instance
                    .collection('adoption_applications')
                    .doc(applicationId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applications Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEF6B39),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                filterStatus = value; // Set the filter status (All, Approved, Rejected)
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('All Applications'),
              ),
              const PopupMenuItem<String>(
                value: 'approved',
                child: Text('Approved'),
              ),
              const PopupMenuItem<String>(
                value: 'rejected',
                child: Text('Rejected'),
              ),
              const PopupMenuItem<String>(
                value: 'pending',
                child: Text('Pending'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredApplications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF6B39)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${filterStatus == 'all' ? '' : filterStatus} applications found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final application = docs[index];
              final applicationData = application.data() as Map<String, dynamic>;

              return GestureDetector(
                onLongPress: () => _showDeleteDialog(application.id),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (applicationData['governmentIdImageUrl'] != null &&
                                applicationData['governmentIdImageUrl'].isNotEmpty) {
                              _showImagePreview(applicationData['governmentIdImageUrl']);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: applicationData['governmentIdImageUrl'] != null &&
                                    applicationData['governmentIdImageUrl'].isNotEmpty
                                ? Image.network(
                                    applicationData['governmentIdImageUrl'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applicationData['fullName'] ?? 'Unknown Applicant',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                applicationData['email'] ?? 'No Email Provided',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(applicationData['status'] ?? 'pending')
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (applicationData['status'] ?? 'PENDING').toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(applicationData['status'] ?? 'pending'),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(
                              (applicationData['submissionDate'] as Timestamp).toDate(),
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Phone', applicationData['phone'] ?? 'N/A'),
                            _buildInfoRow('Address', applicationData['address'] ?? 'N/A'),
                            _buildInfoRow('Work/Monthly Income', applicationData['monthlyIncome'] ?? 'N/A'),
                            _buildInfoRow('Existing Pets', applicationData['existingPets'] ?? 'N/A'),
                            _buildInfoRow('Adoption Reason', applicationData['adoptionReason'] ?? 'N/A'),
                            const Divider(height: 32),
                            // No buttons or messages for approved or rejected applications
                            if (applicationData['status'] != 'approved' && applicationData['status'] != 'rejected') 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _updateApplicationStatus(application.id, 'approved'),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Failed to load image'),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}
