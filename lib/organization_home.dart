import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pawguard/adopt_organization.dart';
import 'package:pawguard/chats_organization.dart';
import 'package:pawguard/profile_organization.dart';
import 'package:pawguard/rescue_organization.dart';

class OrganizationHome extends StatefulWidget {
  const OrganizationHome({super.key});

  @override
  _OrganizationHomeState createState() => _OrganizationHomeState();
}

class _OrganizationHomeState extends State<OrganizationHome> {
  int _selectedIndex = 0;
  bool _showUpcoming = true; // Track whether to show Upcoming or Past Events
  final List<String> categories = ['Adoption', 'Rescue', 'Events'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMainContent(),
          const AdoptOrganizationPage(),
          const RescueOrganizationPage(),
          const ChatsOrganizationPage(),
          const ProfileOrganizationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFEF6B39),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopt'),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  _buildCommercialWidget(),
                  const SizedBox(height: 20.0),
                  FutureBuilder<Widget>(
                    future: _buildStatisticsSection(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                'Error loading statistics: ${snapshot.error}'));
                      }
                      return snapshot.data ?? const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20.0),
                  FutureBuilder<Widget>(
                    future: _buildEventsSection(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                'Error loading events: ${snapshot.error}'));
                      }
                      return snapshot.data ?? const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PawGuard',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF6B39),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF6B39), Color(0xFFFF8E6E)],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Rescue Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Track and manage rescue operations effectively',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2; // Navigate to Rescue tab
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFEF6B39),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0)),
                  ),
                  child: const Text(
                    'View Operations',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/rescue.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildStatisticsSection() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final QuerySnapshot<Map<String, dynamic>> animalsSnapshot =
          await _firestore.collection('animals').get();

      final QuerySnapshot<Map<String, dynamic>> rescueSnapshot =
          await _firestore.collection('rescue_details').get();

      final QuerySnapshot<Map<String, dynamic>> adoptionsSnapshot =
          await _firestore
              .collection('adoption_applications')
              .where('status', isEqualTo: 'approved')
              .get();

      final QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
          await _firestore.collection('events').get();

      int totalPets = animalsSnapshot.docs.length;
      int adoptions = adoptionsSnapshot.docs.length;
      int pendingRescues = rescueSnapshot.docs.length;
      int events = eventsSnapshot.docs.length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      'Total Pets', totalPets.toString(), Icons.pets),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildStatCard(
                      'Adoptions', adoptions.toString(), Icons.favorite),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Rescues', pendingRescues.toString(),
                      Icons.health_and_safety),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child:
                      _buildStatCard('Events', events.toString(), Icons.event),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      return Center(child: Text('Error loading statistics: $e'));
    }
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFEF6B39), size: 32.0),
          const SizedBox(height: 8.0),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF6B39),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildEventsSection() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      // Fetch events data from Firestore
      final QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
          await _firestore.collection('events').orderBy('startDate').get();

      if (eventsSnapshot.docs.isEmpty) {
        return const Center(
          child: Text(
            "No events available.",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      // Filter events based on toggle
      List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredEvents =
          _showUpcoming
              ? eventsSnapshot.docs.where((event) {
                  DateTime startDate =
                      (event['startDate'] as Timestamp).toDate();
                  return startDate.isAfter(DateTime.now());
                }).toList()
              : eventsSnapshot.docs.where((event) {
                  DateTime startDate =
                      (event['startDate'] as Timestamp).toDate();
                  return startDate.isBefore(DateTime.now());
                }).toList();

      // Group events by date
      final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          groupedEvents = _groupEventsByDate(filteredEvents);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Modern Toggle Button and White-Orange Gradient
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Modern Toggle Button
                Container(
                  height: 50,
                  width: 200, // Adjust width for the toggle container
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 240, 231, 213),
                        Color(0xFFEF6B39),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(10), // Fully rounded corners
                    border: Border.all(
                      color: const Color(0xFFEF6B39), // Border color
                      width: .3, // Border thickness
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Subtle shadow for depth
                      ),
                    ],
                  ),

                  padding: const EdgeInsets.all(4), // Inner padding
                  child: Stack(
                    children: [
                      // Highlight background for selected button
                      AnimatedAlign(
                        alignment: _showUpcoming
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(
                            milliseconds: 300), // Smooth animation
                        curve: Curves.easeInOut,
                        child: Container(
                          width: 96, // Width of each button
                          height: 42, // Height slightly less than container
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Highlight color for selected button
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                  0xFFEF6B39), // Border color to match theme
                              width: .3,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Upcoming Button
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showUpcoming = true; // Set to Upcoming
                                });
                              },
                              child: Center(
                                child: Text(
                                  'Upcoming',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _showUpcoming
                                        ? Color(
                                            0xFFEF6B39) // Active text color matches theme
                                        : Colors.white, // Neutral text color
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Past Button
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showUpcoming = false; // Set to Past
                                });
                              },
                              child: Center(
                                child: Text(
                                  'Past',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: !_showUpcoming
                                        ? Color(
                                            0xFFEF6B39) // Active text color matches theme
                                        : Colors.white, // Neutral text color
                                  ),
                                ),
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

            // Event Timeline
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedEvents.keys.length,
              itemBuilder: (context, index) {
                final date = groupedEvents.keys.elementAt(index);
                final events = groupedEvents[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    _buildDateHeader(date),

                    // Events for the date
                    Column(
                      children: events.map((event) {
                        return _buildEventCard(event.data()!);
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return Center(
        child: Text(
          'Error loading events: $e',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
  }

// Group events by date
  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _groupEventsByDate(
          List<QueryDocumentSnapshot<Map<String, dynamic>>> events) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        groupedEvents = {};

    for (var event in events) {
      final startDate = (event['startDate'] as Timestamp).toDate();
      final dateString = DateFormat('yyyy-MM-dd').format(startDate);

      if (!groupedEvents.containsKey(dateString)) {
        groupedEvents[dateString] = [];
      }
      groupedEvents[dateString]!.add(event);
    }

    return groupedEvents;
  }

// Date Header
  Widget _buildDateHeader(String date) {
    final parsedDate = DateTime.parse(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(parsedDate),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                DateFormat('EEEE').format(parsedDate),
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16.0),

          // Vertical Timeline
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 2,
                  color: Colors.grey[300],
                  height: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final startDate = (event['startDate'] as Timestamp).toDate();
    final endDate = (event['endDate'] as Timestamp?)?.toDate();
    final imageUrl = event['imageUrl'] ?? '';
    final title = event['title'] ?? 'Untitled Event';
    final organization = event['organization'] ?? 'Unknown Organization';
    final location = event['location'] ?? 'Virtual';
    final description = event['description'] ?? 'No description available.';

    return GestureDetector(
      onTap: () {
        _showEventDetailsDialog(
          title: title,
          imageUrl: imageUrl,
          organization: organization,
          location: location,
          startDate: startDate,
          endDate: endDate,
          description: description,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEF6B39),
                  ),
                ),
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(width: 16.0),

            // Event Details Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 120,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 120,
                              width: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Details Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time
                            Text(
                              DateFormat('h:mm a').format(startDate),
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Location
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Color(0xFFEF6B39),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetailsDialog({
    required String title,
    required String imageUrl,
    required String organization,
    required String location,
    required DateTime startDate,
    DateTime? endDate,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date and Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('MMM')
                                      .format(startDate)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  DateFormat('d').format(startDate),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy')
                                      .format(startDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat.jm().format(startDate)} - ${endDate != null ? DateFormat.jm().format(endDate) : 'End time not available'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 30,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5, // Line height for readability
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Close Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF6B39),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }
}
