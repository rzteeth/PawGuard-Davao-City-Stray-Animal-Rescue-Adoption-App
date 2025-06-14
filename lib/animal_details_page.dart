import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'terms_and_condition_page.dart';

class OrganizationStats {
  final String label;
  final String value;
  final IconData icon;

  OrganizationStats({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class AnimalDetailsPage extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailsPage({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: _buildBody(context),
              ),
            ],
          ),
          _buildAdoptButton(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width * 0.8,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroImage(context),
      ),
      backgroundColor: const Color(0xFFEF6B39),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    List<String>? images =
        animal['images']?.cast<String>(); //Try to cast to List<String>
    String? imageUrl = animal['mainImage'] ??
        (images?.isNotEmpty ?? false
            ? images![0]
            : animal['image']); //Use first image from list if exists
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    try {
      final String strippedUrl = imageUrl.contains('base64,')
          ? imageUrl.split('base64,')[1]
          : imageUrl;
      final Uint8List imageBytes = base64Decode(strippedUrl.trim());

      return GestureDetector(
        onTap: () => _showEnlargedImage(context, imageBytes),
        child: Hero(
          tag: 'animalImage',
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          ),
        ),
      );
    } catch (e) {
      //Handle Exception
      debugPrint('Error decoding image: $e');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.pets, size: 100, color: Colors.white),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickInfo(),
          const SizedBox(height: 24),
          _buildHealthStatus(context), // Pass context here
          const SizedBox(height: 24),
          _buildHistorySection(),
          const SizedBox(height: 24),
          _buildOrganizationSection(),
          const SizedBox(height: 100), // Space for the adopt button
        ],
      ),
    );
  }

 Widget _buildHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Animal Name
      Text(
        animal['name'] ?? 'Unknown Animal',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
      const SizedBox(height: 16),

      // Activity and Size Modern Buttons
      Wrap(
        spacing: 12.0, // Space between buttons
        runSpacing: 12.0, // Space between rows of buttons
        children: [
          _buildModernButton(animal['activityLevel'] ?? 'Not specified'),
          _buildModernButton(animal['size'] ?? 'Not specified'),
        ],
      ),
    ],
  );
}

// Helper method to build a modern button
Widget _buildModernButton(String label) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEF6C00), Color(0xFFEF6C00)], // Gradient colors (light to deep orange)
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30), // Rounded corners for modern look
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3), // Subtle shadow effect
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4), // Slight downward shadow
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Button padding
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white, // Button text color
        fontSize: 14, // Text size
        fontWeight: FontWeight.w600, // Semi-bold text for a modern look
      ),
    ),
  );
}



  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF6B39).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF6B39).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
              child: _buildInfoItem(
                  Icons.transgender, 'Gender', animal['gender'])),
          _buildDivider(),
          Expanded(child: _buildInfoItem(Icons.pets, 'Breed', animal['breed'])),
          _buildDivider(),
          Expanded(
            child: _buildInfoItem(
              Icons.calendar_today,
              'Age',
              '${animal['age'] ?? 'Unknown'} ${animal['ageUnit'] ?? ''}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String? value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEF6B39).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFEF6B39),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'Unknown',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFEF6B39).withOpacity(0.1),
            Colors.transparent,
            const Color(0xFFEF6B39).withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus(BuildContext context) {
    return Row(
      children: [
        _buildStatusCard(
            context, 'Spayed', animal['spayed'] ?? false, Icons.check_circle),
        const SizedBox(width: 16),
        _buildStatusCard(context, 'Vaccinated', animal['vaccinated'] ?? false,
            Icons.medical_services),
      ],
    );
  }

  Widget _buildStatusCard(
      BuildContext context, String label, bool status, IconData icon) {
    return GestureDetector(
      onTap:
          status ? () => _showVaccineList(context) : null, // Only if vaccinated
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status ? Colors.green[200]! : Colors.red[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: status ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              status ? label : 'Not $label',
              style: TextStyle(
                color: status ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: const Color(0xFFEF6B39), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Animal History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6B39),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final List<Map<String, dynamic>> timelineEvents = [
      {
        'icon': Icons.home_outlined,
        'title': 'Origin',
        'content': animal['origin'] ?? 'Unknown origin',
        'date': animal['arrivalDate'] ?? '---',
      },
      {
        'icon': Icons.access_time,
        'title': 'Time in Shelter',
        'content':
            '${animal['shelterDuration'] ?? 'Unknown'} ${animal['shelterDurationUnit'] ?? ''}',
        'date': '---',
      },
      {
        'icon': Icons.pets_outlined,
        'title': 'Past Experience',
        'content': animal['pastExperience'] ?? 'No past experience recorded',
        'date': '---',
      },
      {
        'icon': Icons.medical_services_outlined,
        'title': 'Medical History',
        'content': animal['medicalHistory'] ?? 'No medical history available',
        'date': '---',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timelineEvents.length,
      itemBuilder: (context, index) {
        final event = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6B39).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      event['icon'] as IconData,
                      size: 16,
                      color: const Color(0xFFEF6B39),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFEF6B39).withOpacity(0.2),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF6B39).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event['date'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFFEF6B39),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['content'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrganizationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF6B39).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF6B39).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: const Color(0xFFEF6B39),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Organization Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6B39),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildOrganizationCard(),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: animal['organization'])
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Get organization data
        Map<String, dynamic>? orgData;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          orgData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6B39).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF6B39).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.pets_outlined,
                      color: Color(0xFFEF6B39),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                animal['organization'] ??
                                    'Organization name not specified',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          orgData?['role'] ?? 'Animal Shelter',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildOrganizationDetail(
                Icons.location_on_outlined,
                'Location',
                orgData?['address'] ?? 'Address not specified',
              ),
              const SizedBox(height: 16),
              _buildOrganizationDetail(
                Icons.phone_outlined,
                'Contact',
                orgData?['phone'] ?? 'Contact not available',
              ),
              const SizedBox(height: 16),
              _buildOrganizationDetail(
                Icons.email_outlined,
                'Email',
                orgData?['email'] ?? 'Email not available',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrganizationDetail(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF6B39).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF6B39).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdoptButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEF6B39),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF6B39).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Adopt',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVaccineList(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Slightly darker barrier
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor:
                Colors.transparent, // Transparent background for the Dialog
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4), // Adjust offset as needed
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vaccines Administered',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (animal['vaccines'] != null &&
                      animal['vaccines'].isNotEmpty)
                    ...animal['vaccines']
                        .map((vaccine) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 18, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    // Allow text to wrap if needed
                                    child: Text(
                                      vaccine.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList()
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Center(
                        child: Text(
                          'No vaccine information available.',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CLOSE'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEnlargedImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Animated background
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            // Main image viewer
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Image with InteractiveViewer
                      InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(20),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Close button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      // Zoom hint
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_out_map,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pinch to zoom',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
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
          ],
        );
      },
    );
  }
}
