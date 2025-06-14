import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pawguard/adopt_user_page.dart';
import 'package:pawguard/animal_details_page.dart';
import 'package:pawguard/rescue_user_page.dart';
import 'package:pawguard/chats_user_page.dart';
import 'package:pawguard/profile_user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pet {
  final String id;
  final String name;
  final String breed;
  final String description;
  final String age;
  final String ageUnit;
  final String gender;
  final List<String> images;
  final String organization;
  final bool spayed;
  final bool vaccinated;
  final String type; // Updated from species to type to match Firestore
  final String activityLevel;
  final String size;
  // Animal History fields
  final String origin;
  final String shelterDuration;
  final String shelterDurationUnit;
  final String pastExperience;
  final String medicalHistory;
  final List<String> vaccines;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.description,
    required this.age,
    required this.ageUnit,
    required this.gender,
    required this.images,
    required this.organization,
    required this.spayed,
    required this.vaccinated,
    required this.type, // Updated field for type
    required this.activityLevel,
    required this.size,
    required this.origin,
    required this.shelterDuration,
    required this.shelterDurationUnit,
    required this.pastExperience,
    required this.medicalHistory,
    required this.vaccines,
  });

  factory Pet.fromMap(Map<String, dynamic> map, String id) {
    return Pet(
      id: id,
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      description: map['description'] ?? '',
      age: map['age'] ?? '',
      ageUnit: map['ageUnit'] ?? '',
      gender: map['gender'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      organization: map['organization'] ?? '',
      spayed: map['spayed'] ?? false,
      vaccinated: map['vaccinated'] ?? false,
      type: map['type'] ?? '', // Map 'type' from Firestore
      activityLevel: map['activityLevel'] ?? '', // Map activityLevel
      size: map['size'] ?? '', // Map size
      origin: map['origin'] ?? '', // Map origin
      shelterDuration: map['shelterDuration'] ?? '', // Map shelterDuration
      shelterDurationUnit:
          map['shelterDurationUnit'] ?? '', // Map shelterDurationUnit
      pastExperience: map['pastExperience'] ?? '', // Map pastExperience
      medicalHistory: map['medicalHistory'] ?? '', // Map medicalHistory
      vaccines: List<String>.from(map['vaccines'] ?? []), // Map vaccines
    );
  }

  // Method to get age and ageUnit combined as a string
  String get fullAge => '$age $ageUnit';

  // Method to get full shelter duration
  String get fullShelterDuration => '$shelterDuration $shelterDurationUnit';
}

class CommercialItem {
  final String title;
  final String subheading;
  final String imagePath;
  final String buttonText;

  CommercialItem({
    required this.title,
    required this.subheading,
    required this.imagePath,
    required this.buttonText,
  });
}

class UserHomePage extends StatefulWidget {
  final String? selectedType;
  final String? selectedActivityLevel;
  final String? selectedSize;

  const UserHomePage({
    Key? key,
    this.selectedType,
    this.selectedActivityLevel,
    this.selectedSize,
  }) : super(key: key);

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final PageController _featuredController =
      PageController(viewportFraction: 0.85, initialPage: 0);
  late Timer _timer;
  int _currentCommercialPage = 0;
  List<String> _selectedPreferences = []; // Added to store preferences
  bool _showUpcoming = true; // Track whether to show Upcoming or Past Events

  final List<CommercialItem> commercialData = [
    CommercialItem(
      title: 'Rescue a Pet Today!',
      subheading: 'Give them a second chance at happiness.',
      imagePath: 'assets/rescue.png',
      buttonText: 'Rescue Now',
    ),
    CommercialItem(
      title: 'Adopt a Companion!',
      subheading: 'Find your perfect furry friend.',
      imagePath: 'assets/adopt_us.png',
      buttonText: 'Adopt Now',
    ),
  ];

  int notificationCount = 0;

  void fetchNotificationCount() async {
    // Example: Fetch from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('read', isEqualTo: false) // Filter unread notifications
        .get();

    setState(() {
      notificationCount = snapshot.docs.length; // Update notification count
    });
  }

  Stream<List<Pet>> _getFilteredPetsStream() {
    Query query = FirebaseFirestore.instance.collection('animals');

    // Apply filters dynamically
    if (widget.selectedType != null) {
      query = query.where('type', isEqualTo: widget.selectedType);
    }
    if (widget.selectedSize != null) {
      query = query.where('size', isEqualTo: widget.selectedSize);
    }
    if (widget.selectedActivityLevel != null) {
      query =
          query.where('activityLevel', isEqualTo: widget.selectedActivityLevel);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load preferences on initialization
    _startAutoScroll();
    fetchNotificationCount();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPreferences = prefs.getStringList('selectedPreferences') ?? [];
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _currentCommercialPage =
            (_currentCommercialPage + 1) % commercialData.length;
        _pageController.animateToPage(
          _currentCommercialPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _featuredController.dispose();
    super.dispose();
  }

  Widget _buildCommercialContainer(CommercialItem commercial) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 150, // Fixed height for the container
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF6B39),
            const Color(0xFFFF8E6E),
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Section: Text and Button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 12.0, 8.0, 12.0), // Adjusted padding for the left side
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    commercial.title,
                    style: const TextStyle(
                      fontSize: 18.0, // Adjusted font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    commercial.subheading,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: 120, // Fixed button width
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate based on button text
                        if (commercial.buttonText == 'Rescue Now') {
                          setState(() {
                            _selectedIndex = 2; // Index for Rescue page
                          });
                        } else if (commercial.buttonText == 'Adopt Now') {
                          setState(() {
                            _selectedIndex = 1; // Index for Adopt page
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF6B39),
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0, // Reduced vertical padding
                        ),
                        minimumSize: const Size(0, 35), // Minimum button height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                      child: Text(
                        commercial.buttonText,
                        style: const TextStyle(
                          fontSize:
                              14.0, // Reduced font size for the button text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Section: Image with Margin
          Container(
            margin: const EdgeInsets.only(
                right: 8.0), // Add margin to the right of the image
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Image.asset(
                commercial.imagePath,
                width: 120, // Fixed width for the image
                height: double.infinity, // Full height of the container
                fit: BoxFit.contain, // Ensures the image is fully visible
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFeaturedCard(Pet pet) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalDetailsPage(
            animal: {
              'name': pet.name,
              'breed': pet.breed,
              'description': pet.description,
              'age': '${pet.age} ${pet.ageUnit}', // Include age and ageUnit
              'gender': pet.gender,
              'images': pet.images,
              'organization': pet.organization,
              'spayed': pet.spayed,
              'vaccinated': pet.vaccinated,
              'vaccines': pet.vaccines, // Include vaccines here
              'species': pet.type,
              'activityLevel': pet.activityLevel, // Include activityLevel
              'size': pet.size, // Include size
              'origin': pet.origin,
              'shelterDuration':
                  '${pet.shelterDuration} ${pet.shelterDurationUnit}', // Include shelterDuration and unit
              'pastExperience': pet.pastExperience,
              'medicalHistory': pet.medicalHistory,
            },
          ),
        ),
      );
    },
    child: Container(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: pet.images.isNotEmpty
                        ? Image.memory(
                            base64Decode(pet.images[0].split(',')[1]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Text('Error loading image'));
                            },
                          )
                        : Center(child: Text('No Image Available')),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pet.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pet.organization,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPetInfoChip(pet.breed),
                              SizedBox(width: 8),
                              // Updated line to display age properly
                              _buildPetInfoChip('${pet.age} ${pet.ageUnit}'),
                              SizedBox(width: 8),
                              _buildPetInfoChip(pet.gender),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            pet.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              _buildVaccinationStatus(pet.vaccinated),
                              SizedBox(width: 16),
                              _buildSpayNeuterStatus(pet.spayed),
                            ],
                          ),
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
                        return _buildEventCard(event.data());
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

  Widget _buildPetInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildVaccinationStatus(bool isVaccinated) {
    return Row(
      children: [
        Icon(
          isVaccinated ? Icons.check_circle : Icons.cancel,
          color: isVaccinated ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 4),
        Text(
          'Vaccinated',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSpayNeuterStatus(bool isSpayed) {
    return Row(
      children: [
        Icon(
          isSpayed ? Icons.check_circle : Icons.cancel,
          color: isSpayed ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 4),
        Text(
          'Spayed/Neutered',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Featured Pets',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: StreamBuilder<List<Pet>>(
            stream: _getFilteredPetsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading pets'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pets = snapshot.data ?? [];

              if (pets.isEmpty) {
                return const Center(
                  child: Text('No pets matching your preferences.'),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16.0),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: _buildFeaturedCard(pets[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Pet> _filterPets(List<Pet> pets) {
    if (_selectedPreferences.isEmpty) {
      return pets;
    }
    return pets.where((pet) {
      return _selectedPreferences.any((preference) {
        return pet.breed.toLowerCase().contains(preference.toLowerCase()) ||
            pet.description.toLowerCase().contains(preference.toLowerCase()) ||
            pet.type.toLowerCase().contains(preference.toLowerCase());
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0), // Add vertical padding
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PawGuard',
                              style: TextStyle(
                                fontSize: 26.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF6B39),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 200.0,
                          margin: const EdgeInsets.symmetric(vertical: 16.0),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: commercialData.length,
                            itemBuilder: (context, index) {
                              return _buildCommercialContainer(
                                  commercialData[index]);
                            },
                          ),
                        ),
                        _buildFeaturedSection(),
                        SizedBox(height: 24.0),
                        FutureBuilder<Widget>(
                          future: _buildEventsSection(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return snapshot.data!;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AdoptUserPage(),
          RescueUserPage(),
          ChatsUserPage(),
          ProfileUserPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFEF6B39),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopt'),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: 'Rescue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
