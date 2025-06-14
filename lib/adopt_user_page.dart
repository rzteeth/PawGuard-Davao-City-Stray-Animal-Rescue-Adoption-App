import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'animal_details_page.dart';

class AdoptUserPage extends StatefulWidget {
  const AdoptUserPage({super.key});

  @override
  _AdoptUserPageState createState() => _AdoptUserPageState();
}

class _AdoptUserPageState extends State<AdoptUserPage> {
  Set<String> likedAnimals = {};
  String? selectedBreed;
  bool showFilters = false;
  bool _filtersOverlayVisible = false;
  TextEditingController searchController = TextEditingController();
  int adoptedAnimalCount = 0;
  String? selectedAgeGroup;

  String? selectedPetType;
  String? selectedActivityLevel;
  String? selectedSize;
  String? selectedGender;
  RangeValues ageRange = const RangeValues(0, 20);

  // App's color scheme
  final Color primaryColor = Color(0xFFEF6B39);
  final Color secondaryColor = Color(0xFF2E3E5C);
  final Color backgroundColor = Color(0xFFF5F6FA);
  final Color textColor = Color(0xFF1F2937);
  final Color subtitleColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                _buildAppBar(),
                Expanded(
                  child: _buildPetGrid(),
                ),
              ],
            ),
            if (_filtersOverlayVisible) _buildFilterOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find Your Pet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF6B39),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      showFilters ? Icons.close : Icons.tune,
                      color: textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        showFilters = !showFilters;
                        _filtersOverlayVisible = !_filtersOverlayVisible;
                      });
                    },
                  ),
                  IconButton(
                    // Added IconButton for adopted animals
                    icon: Stack(
                      children: [
                        Icon(Icons.pets, color: textColor),
                        if (adoptedAnimalCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                adoptedAnimalCount.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      // Navigate to the adopted animals page here
                      // For example:
                      Navigator.pushNamed(context, '/adoptedAnimals');
                    },
                  ),
                ],
              ),
            ),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: TextField(
          controller: searchController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Search pets by name...',
            hintStyle: TextStyle(color: subtitleColor),
            prefixIcon: Icon(Icons.search, color: subtitleColor),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draggable Handle
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Pets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _filtersOverlayVisible = false;
                              showFilters = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  // Filter Content
                  Flexible(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection(
                              'Pet Type', _buildPetTypeFilter()),
                          SizedBox(height: 24), // Space between filters
                          _buildFilterSection(
                              'Activity Level', _buildActivityLevelFilter()),
                          SizedBox(height: 24), // Space between filters
                          _buildFilterSection('Size', _buildSizeFilter()),
                          SizedBox(height: 24), // Space between filters
                          _buildFilterSection('Gender', _buildGenderFilter()),
                          SizedBox(height: 24), // Space after last filter
                        ],
                      ),
                    ),
                  ),
                  // Buttons
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetFilters,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.orange),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _filtersOverlayVisible = false;
                                  showFilters = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ],
        ),
      ),
    );
  }

// Reusable filter section wrapper
  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        content,
      ],
    );
  }

// Pet Type Filter
  Widget _buildPetTypeFilter() {
    final petTypes = ['Dog', 'Cat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: petTypes.map((type) {
        final isSelected = selectedPetType == type;
        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedPetType = isSelected ? null : type;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 8), // Add space between options
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    color: isSelected ? Colors.orange : Colors.grey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

// Activity Level Filter (No Icons)
  Widget _buildActivityLevelFilter() {
    final activityLevels = ['Playful', 'Calm', 'Energetic', 'Loving'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: activityLevels.map((level) {
        final isSelected = selectedActivityLevel == level;
        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedActivityLevel = isSelected ? null : level;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 4), // Add space between options
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.grey[600],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

// Size Filter
  Widget _buildSizeFilter() {
    final sizes = ['Small', 'Medium', 'Large'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: sizes.map((size) {
        final isSelected = selectedSize == size;
        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedSize = isSelected ? null : size;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 8), // Add space between options
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.straighten,
                    color: isSelected ? Colors.orange : Colors.grey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    size,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

// Gender Filter
  Widget _buildGenderFilter() {
    final genders = ['Male', 'Female', 'All'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: genders.map((gender) {
        final isSelected = selectedGender == gender ||
            (gender == 'All' && selectedGender == null);
        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedGender = gender == 'All' ? null : gender;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 8), // Add space between options
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    gender == 'Male'
                        ? Icons.male
                        : gender == 'Female'
                            ? Icons.female
                            : Icons.all_inclusive,
                    color: isSelected ? Colors.orange : Colors.grey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    gender,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPetGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('animals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        var animals = snapshot.data!.docs;
        animals = _filterAnimals(animals);

        if (animals.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: animals.length,
              itemBuilder: (context, index) {
                return _buildPetCard(animals[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPetCard(QueryDocumentSnapshot<Object?> animal) {
    final data = animal.data() as Map<String, dynamic>;

    // Decode the first image in the 'images' array
    List<String>? images = data['images']?.cast<String>();
    Uint8List? imageBytes;
    if (images != null && images.isNotEmpty) {
      imageBytes = _decodeImage(images[0]);
    }

    return GestureDetector(
      onTap: () => _navigateToDetails(data),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Image Container
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Container(
                      color: Colors.grey[200],
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // Details Container
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        data['breed'] ?? 'Unknown breed',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: primaryColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['organization'] ?? 'Unknown location',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtitleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: subtitleColor,
          ),
          SizedBox(height: 16),
          Text(
            'No pets found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 16,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  // Utility Methods
  List<QueryDocumentSnapshot> _filterAnimals(
      List<QueryDocumentSnapshot> animals) {
    return animals.where((animal) {
      final data = animal.data() as Map<String, dynamic>;

      // Search filter
      if (searchController.text.isNotEmpty &&
          !data['name'].toString().toLowerCase().contains(
                searchController.text.toLowerCase(),
              )) {
        return false;
      }

      // Pet Type filter
      if (selectedPetType != null && data['type'] != selectedPetType) {
        return false;
      }

      // Activity Level filter
      if (selectedActivityLevel != null &&
          data['activityLevel'] != selectedActivityLevel) {
        return false;
      }

      // Size filter
      if (selectedSize != null && data['size'] != selectedSize) {
        return false;
      }

      // Gender filter
      if (selectedGender != null &&
          selectedGender != 'All' &&
          data['gender'] != selectedGender) {
        return false;
      }

      // Age filter
      final age = double.tryParse(data['age'].toString()) ?? 0;
      if (age < ageRange.start || age > ageRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      selectedPetType = null;
      selectedActivityLevel = null;
      selectedSize = null;
      selectedGender = null;
    });
  }

  void _navigateToDetails(Map<String, dynamic> animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalDetailsPage(animal: animal),
      ),
    ).then((value) {
      if (value == true) {
        // Check if adoption was successful
        setState(() {
          adoptedAnimalCount++;
        });
      }
    });
  }

  Uint8List? _decodeImage(String? base64String) {
    if (base64String == null) return null;
    try {
      final base64Image = base64String.split(',').last;
      return base64Decode(base64Image);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }
}
