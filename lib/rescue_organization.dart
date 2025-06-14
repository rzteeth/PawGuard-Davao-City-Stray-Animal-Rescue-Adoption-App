import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class RescueOrganizationPage extends StatefulWidget {
  const RescueOrganizationPage({Key? key}) : super(key: key);

  @override
  _RescueOrganizationPageState createState() => _RescueOrganizationPageState();
}

class _RescueOrganizationPageState extends State<RescueOrganizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkFirestoreConnection();
  }

  Future<void> _checkFirestoreConnection() async {
    try {
      await _firestore.collection('rescue_details').limit(1).get();
      print('Connected to Firestore successfully');
    } catch (error) {
      print('Firestore connection error: $error');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFEF6B39),
          centerTitle: false,
          elevation: 0,
          title: const Text(
            'Rescue Reports',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'ALL'),
              Tab(text: 'PENDING'),
              Tab(text: 'APPROVED'),
              Tab(text: 'REJECTED'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildReportList('all'),
                _buildReportList('pending'),
                _buildReportList('approved'),
                _buildReportList('rejected'),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6B39)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildReportList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('rescue_details')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading reports\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6B39)),
            ),
          );
        }

        final allReports = snapshot.data?.docs ?? [];
        final reports = status == 'all'
            ? allReports
            : allReports.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final reportStatus = data['status'] as String? ?? 'pending';
                return reportStatus == status;
              }).toList();

        if (reports.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          color: const Color(0xFFEF6B39),
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 1500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildReportCard(data, doc.id, data['status'] ?? 'pending');
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'pending'
                ? Icons.pending_actions
                : status == 'approved'
                    ? Icons.check_circle_outline
                    : status == 'rejected'
                        ? Icons.cancel_outlined
                        : Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            status == 'all'
                ? 'No rescue reports available'
                : 'No ${status.toLowerCase()} reports',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtext(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateSubtext(String status) {
    switch (status) {
      case 'pending':
        return 'No new rescue reports need your attention';
      case 'approved':
        return 'No rescue reports have been approved yet';
      case 'rejected':
        return 'No rescue reports have been rejected';
      default:
        return 'Start receiving rescue reports from users';
    }
  }

 Widget _buildReportCard(Map<String, dynamic> data, String docId, String status) {
  final timestamp = data['timestamp'] as Timestamp?;
  final formattedDate = timestamp != null ? _formatTimestamp(timestamp) : 'Date not available';
  final imageUrl = data['image_url'] as String?;

  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: () => _showDetailedView(data, docId, status),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorImage(); // Handle failed image loading
                  },
                ),
              ),
            )
          else
            _buildPlaceholderImage(), // Handle cases with no image
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['animal_type']?.toString().capitalize() ?? 'Unknown Animal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No description provided',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      data['contact'] ?? 'No contact',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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
}



Widget _buildPlaceholderImage() {
  return Container(
    height: 150,
    color: Colors.grey[200],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('No Image Available', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}




  Widget _buildDetailsCard(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection(
              'Rescue Details',
              [
                _buildDetailRow('Animal Type', data['animal_type']?.toString().capitalize() ?? 'Unknown', Icons.pets),
                if (data['specific_animal_type'] != null && data['specific_animal_type'].toString().isNotEmpty)
                  _buildDetailRow('Specific Type', data['specific_animal_type'].toString(), Icons.pets_outlined),
                _buildDetailRow('Description', data['description'] ?? 'No description provided', Icons.description),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailSection(
              'Contact & Location',
              [
                _buildDetailRow('Contact Number', data['contact'] ?? 'Not provided', Icons.phone),
                _buildDetailRow('Location', data['location'] ?? 'Location not specified', Icons.location_on),
              ],
            ),
            if (data['actionComment'] != null && data['actionComment'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildDetailSection(
                'Admin Comment',
                [
                  _buildDetailRow('Comment', data['actionComment'].toString(), Icons.comment),
                ],
              ),
            ],
            if (data['actionTimestamp'] != null) ...[
              const SizedBox(height: 20),
              _buildDetailSection(
                'Action Details',
                [
                  _buildDetailRow(
                    'Action Date',
                    _formatTimestamp(data['actionTimestamp'] as Timestamp),
                    Icons.calendar_today,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF6B39),
          ),
        ),
        const SizedBox(height: 12),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            )),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF6B39).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFEF6B39),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildImageWidget(String imageString) {
    try {
      if (imageString.startsWith('data:image') || imageString.contains('base64')) {
        String base64String = imageString;
        if (base64String.contains(',')) {
          base64String = base64String.split(',')[1];
        }
        base64String = base64String.trim();
        
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        );
      } else if (imageString.startsWith('http')) {
        return Image.network(
          imageString,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF6B39)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        );
      } else if (imageString.startsWith('/')) {
        return Image.file(
          File(imageString),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        );
      } else {
        return _buildErrorImage();
      }
    } catch (e) {
      print('Error processing image: $e');
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedView(Map<String, dynamic> data, String docId, String status) {
  final imageString = data['image_url'] as String?;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Drag Indicator
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 5,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            // Main Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  // Title Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF6B39),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Rescue Request',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image Section
                  if (imageString != null && imageString.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () => _showImagePreview(context, imageString),
                        child: Hero(
                          tag: 'rescue_image_$docId',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _buildImageWidget(imageString),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Map Section
                  if (_hasValidCoordinates(data)) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildMap(data),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Details Card
                  Container(
                    margin: EdgeInsets.only(
                      bottom: status == 'pending' ? 100 : 24,
                    ),
                    child: _buildDetailsCard(data),
                  ),
                ],
              ),
            ),

            // Sticky Bottom Buttons
            if (status == 'pending')
              Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(docId, 'reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'REJECT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(docId, 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'APPROVE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  void _showSuccessDialog(String action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: action == 'approve'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: action == 'approve' ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  action == 'approve'
                      ? 'Report Approved Successfully!'
                      : 'Report Rejected Successfully!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  action == 'approve'
                      ? 'The rescue report has been approved and moved to the approved section.'
                      : 'The rescue report has been rejected and moved to the rejected section.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _tabController.animateTo(
                        action == 'approve' ? 2 : 3,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          action == 'approve' ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      action == 'approve'
                          ? 'Go to Approved Reports'
                          : 'Go to Rejected Reports',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> _showConfirmationDialog(String docId, String action) async {
  String? comment;
  final primaryColor = action == 'approve' ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
  final backgroundColor = action == 'approve' 
      ? const Color(0xFF4CAF50).withOpacity(0.9)
      : const Color(0xFFE53935).withOpacity(0.9);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2),
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85, // Reduced width
                maxHeight: MediaQuery.of(context).size.height * 0.6, // Reduced height
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Icon - Reduced padding
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20), // Reduced padding
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12), // Reduced padding
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                            action == 'approve' ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 36, // Reduced size
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced spacing
                        Text(
                          '${action.capitalize()} Report',
                          style: const TextStyle(
                            fontSize: 22, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20,
                            MediaQuery.of(context).viewInsets.bottom + 20), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Are you sure you want to ${action.toLowerCase()} this rescue report?',
                              style: TextStyle(
                                fontSize: 15, // Reduced font size
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20), // Reduced spacing
                            
                            // Comment TextField
                            TextField(
                              onChanged: (value) => comment = value,
                              decoration: InputDecoration(
                                labelText: 'Add a comment (optional)',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                hintText: 'Enter your comment here...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: backgroundColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 3,
                              style: const TextStyle(fontSize: 14), // Reduced font size
                            ),
                            
                            const SizedBox(height: 20), // Reduced spacing

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14, // Reduced font size
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12), // Reduced spacing
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: backgroundColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      action.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 14, // Reduced font size
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  if (confirmed == true) {
    await _handleAction(docId, action, comment);
  }
}


  Future<void> _handleAction(String docId, String action, String? comment) async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> updateData = {
        'status': action == 'approve' ? 'approved' : 'rejected',
        'actionTimestamp': FieldValue.serverTimestamp(),
        'actionBy': currentUser?.uid,
      };

      if (comment != null && comment.trim().isNotEmpty) {
        updateData['actionComment'] = comment;
      }

      await _firestore.collection('rescue_details').doc(docId).update(updateData);

      if (mounted) {
        Navigator.pop(context); // Close the detailed view
        _showSuccessDialog(action);
      }
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to ${action} report'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMap(Map<String, dynamic> data) {
    try {
      final lat = data['latitude'] as double;
      final lng = data['longitude'] as double;

      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: latLng.LatLng(lat, lng),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng.LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building map: $e');
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Error loading map'),
        ),
      );
    }
  }

  bool _hasValidCoordinates(Map<String, dynamic> data) {
    final lat = data['latitude'];
    final lng = data['longitude'];
    return lat != null && lng != null && lat is double && lng is double;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: _buildImageWidget(imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
