import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';

import 'package:pawguard/manage_pets.dart';

class AdoptOrganizationPage extends StatefulWidget {
  const AdoptOrganizationPage({Key? key}) : super(key: key);

  @override
  _AdoptOrganizationPageState createState() => _AdoptOrganizationPageState();
}

class _AdoptOrganizationPageState extends State<AdoptOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _shelterDurationController =
      TextEditingController();
  final TextEditingController _pastExperienceController =
      TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();

  final primaryColor = const Color(0xFFEF6C00); // Deep Orange
  final secondaryColor = const Color(0xFFFF9800); // Orange
  final backgroundColor = const Color.fromARGB(255, 255, 255, 255);
  final errorColor = const Color(0xFFB71C1C); // Error Red
  final surfaceColor = Colors.white;
  final cardColor = Colors.white;
  final double borderRadius = 16.0;
  final double spacing = 20.0;

  String _selectedType = 'Dog';
  String _selectedGender = 'Male';
  String _selectedAgeUnit = 'Years';
  String _selectedShelterDurationUnit = 'Months';
  bool _spayed = false;
  bool _vaccinated = false;
  List<String> _selectedVaccines = [];
  List<File?> _images = List.generate(5, (index) => null);
  final picker = ImagePicker();

  final List<String> _vaccines = [
    'Distemper',
    'Rabies',
    'Parvo',
    'Canine Influenza',
    'Feline Leukemia',
    'DAPPv',
    'Bordetella',
    'FVRCP',
    'FELV',
    'FVRCP booster',
    'FELV booster'
  ];

  String? selectedActivity; // Variable to hold the selected Description option
  String? selectedSize;

  final List<String> activityOptions = [
    'Playful',
    'Calm',
    'Energetic',
    'Loving',
  ];

  final List<String> sizeOptions = [
    'Small',
    'Medium',
    'Large',
  ];

  @override
  void initState() {
    super.initState();
    _populateOrganizationField();
  }

// Fetch the logged-in user's organization name from Firestore
  Future<void> _populateOrganizationField() async {
    try {
      // Get the currently logged-in user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch the user's document from Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if the document exists and has a `name` field
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String? organizationName =
              data['name']; // Replace `name` with your actual field

          if (organizationName != null && organizationName.isNotEmpty) {
            // Set the organization's name in the text field
            setState(() {
              _organizationController.text = organizationName;
            });
          } else {
            _organizationController.text = 'No Organization Name Set';
          }
        } else {
          _organizationController.text = 'No Organization Name Set';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching organization name: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize:
          const Size.fromHeight(70.0), // Custom height (default is 56.0)
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: const Text(
          'Add Pet for Adoption',
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        //centerTitle: false,
        // actions: [
        //IconButton(
        // icon: Icon(Icons.pets_rounded, color: Colors.white),
        // onPressed: () {
        // Navigator.push(
        //  context,
        //  MaterialPageRoute(
        //    builder: (context) => ManagePetsPage(),
        //  ),
        // );
        //  },
        //tooltip: 'Manage Added Pets',
        //  ),
        //  ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              SizedBox(height: spacing),
              _buildBasicInfoSection(),
              SizedBox(height: spacing),
              _buildDetailsSection(),
              SizedBox(height: spacing),
              _buildHealthSection(),
              SizedBox(height: spacing),
              _buildHistorySection(),
              SizedBox(height: spacing * 1.5),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 4, // Slightly higher elevation for better depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16), // Increased padding for a spacious feel
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pet Photos', Icons.photo_library),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount:
                  1, // Only showing 1 image for now, you can modify as per need
              itemBuilder: (context, index) => _buildImagePicker(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(int index) {
    return InkWell(
      onTap: () => _pickImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: _images[index] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _images[index]!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: primaryColor.withOpacity(0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 4, // Slightly increased elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Information', Icons.info_outline),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Pet Name',
              icon: Icons.pets,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _organizationController,
              label: 'Organization',
              icon: Icons.business,
              readOnly: true, // This makes the field read-only
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              'Pet Type',
              _selectedType,
              ['Dog', 'Cat'],
              (value) => setState(() => _selectedType = value!),
            ),
            if (_selectedType == 'Other') ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _otherTypeController,
                label: 'Specify Pet Type',
                icon: Icons.help_outline,
              ),
            ],
            const SizedBox(height: 16),
            _buildDropdownField(
              'Gender',
              _selectedGender,
              ['Male', 'Female'],
              (value) => setState(() => _selectedGender = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pet Details', Icons.pets),
            const SizedBox(height: 20),

            // Breed Text Field
            _buildTextField(
              controller: _breedController,
              label: 'Breed',
              icon: Icons.pets_outlined,
            ),
            const SizedBox(height: 16),

            // Age Input Section
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      icon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        // Trigger a rebuild on age change to update the unit text
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAgeUnit,
                    items: _getAgeUnits(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgeUnit = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Level Section
            const Text(
              'Activity Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityButtons(),
            const SizedBox(height: 16),

            // Size Section
            const Text(
              'Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSizeButtons(),
          ],
        ),
      ),
    );
  }

// Helper function to get dynamic age units based on input
  List<DropdownMenuItem<String>> _getAgeUnits() {
    final int age = int.tryParse(_ageController.text) ?? 0;
    return [
      DropdownMenuItem(
        value: 'Months',
        child: Text(age == 1 ? 'Month' : 'Months'),
      ),
      DropdownMenuItem(
        value: 'Years',
        child: Text(age == 1 ? 'Year' : 'Years'),
      ),
    ];
  }

  // Updated method to create buttons for Description
  Widget _buildActivityButtons() {
    return Wrap(
      spacing: 8.0, // Horizontal space between buttons
      runSpacing: 8.0, // Vertical space between rows of buttons
      children: activityOptions.map((option) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: selectedActivity == option
                ? Colors.white // Text color when selected
                : Colors.black,
            backgroundColor: selectedActivity == option
                ? Color(0xFFFF9800) // Selected color
                : Colors.white, // Text color when not selected
          ),
          onPressed: () {
            setState(() {
              selectedActivity = option;
            });
          },
          child: Text(option),
        );
      }).toList(),
    );
  }

  Widget _buildSizeButtons() {
    return Wrap(
      spacing: 8.0, // Horizontal space between buttons
      runSpacing: 8.0, // Vertical space between rows of buttons
      children: sizeOptions.map((option) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: selectedSize == option
                ? Colors.white // Text color when selected
                : Colors.black,
            backgroundColor: selectedSize == option
                ? Color(0xFFFF9800) // Selected color
                : Colors.white, // Text color when not selected
          ),
          onPressed: () {
            setState(() {
              selectedSize = option;
            });
          },
          child: Text(option),
        );
      }).toList(),
    );
  }

  Widget _buildHealthSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Health Information', Icons.medical_services),
            const SizedBox(height: 20),
            _buildSwitchTile(
              'Spayed/Neutered',
              _spayed,
              (value) => setState(() => _spayed = value),
            ),
            _buildSwitchTile(
              'Vaccinated',
              _vaccinated,
              (value) => setState(() => _vaccinated = value),
            ),
            if (_vaccinated) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Vaccines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vaccines.map((vaccine) {
                  return FilterChip(
                    label: Text(vaccine),
                    selected: _selectedVaccines.contains(vaccine),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedVaccines.add(vaccine);
                        } else {
                          _selectedVaccines.remove(vaccine);
                        }
                      });
                    },
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _medicalHistoryController,
              label: 'Medical History',
              icon: Icons.medical_services_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildHistorySection() {
  return Card(
    elevation: 4, // Increased elevation for a more distinct 3D effect
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // Rounded corners for a modern feel
    ),
    child: Padding(
      padding: const EdgeInsets.all(16), // Spacious padding for better layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Background History', Icons.history),
          const SizedBox(height: 24), // Increased spacing for better readability

          // Origin/Background Field
          _buildTextField(
            controller: _originController,
            label: 'Origin/Background',
            icon: Icons.location_history,
            maxLines: 3,
            fillColor: Colors.grey[100]!, // Subtle background for clarity
          ),
          const SizedBox(height: 24), // More space between sections

          // Time in Shelter Section
          Text(
            'Time in Shelter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          // Shelter Duration Input
          TextFormField(
            controller: _shelterDurationController,
            decoration: InputDecoration(
              labelText: 'Number of (weeks/months/years) in Shelter',
              icon: Icon(Icons.timer),
              filled: true,
              fillColor: Colors.grey[50], // Light background for readability
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                // Trigger rebuild to update unit dynamically
              });
            },
          ),
          const SizedBox(height: 16),

          // Duration Unit Dropdown
          Text(
            'Select Duration', // Clarified the dropdown label
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedShelterDurationUnit,
            items: _getDurationUnits(),
            onChanged: (value) {
              setState(() {
                _selectedShelterDurationUnit = value!;
              });
            },
            decoration: InputDecoration(
              labelText: 'Duration',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24), // Space between sections

          // Past Experiences Field
          _buildTextField(
            controller: _pastExperienceController,
            label: 'Past Experiences',
            icon: Icons.history_edu,
            maxLines: 3,
            fillColor: Colors.grey[100]!, // Subtle background for clarity
          ),
        ],
      ),
    ),
  );
}

// Helper function to get dynamic duration units
List<DropdownMenuItem<String>> _getDurationUnits() {
  final int duration = int.tryParse(_shelterDurationController.text) ?? 0;

  return [
    DropdownMenuItem(
      value: 'Weeks',
      child: Text(duration == 1 ? 'Week' : 'Weeks'),
    ),
    DropdownMenuItem(
      value: 'Months',
      child: Text(duration == 1 ? 'Month' : 'Months'),
    ),
    DropdownMenuItem(
      value: 'Years',
      child: Text(duration == 1 ? 'Year' : 'Years'),
    ),
  ];
}


  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false, // Default to false for editable fields
    int maxLines = 1,
    TextInputType? keyboardType,
    Color? fillColor,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly, // This ensures the field is read-only
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
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
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'This field is required' : null,
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () => _submitForm(),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Text(
        'Submit Pet Profile',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final tempDir = Directory.systemTemp;
        final targetPath =
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          quality: 85,
          minWidth: 1024,
          minHeight: 1024,
        );

        if (compressedFile != null) {
          setState(() {
            _images[index] = File(compressedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Process images for upload (if any)
      final List<String> base64Images = await _processImagesForUpload();
      String finalType = _selectedType;
      if (_selectedType == 'Other') finalType = _otherTypeController.text;

      // Get the age and ageUnit from the input fields
      final int age = int.tryParse(_ageController.text) ?? 0;
      final String ageUnit = age == 1
          ? (_selectedAgeUnit == 'Years' ? 'Year' : 'Month')
          : (_selectedAgeUnit == 'Years' ? 'Years' : 'Months');

      // Get the shelter duration and unit dynamically
      final int shelterDuration = int.tryParse(_shelterDurationController.text) ?? 0;
      final String shelterDurationUnit = shelterDuration == 1
          ? (_selectedShelterDurationUnit == 'Years'
              ? 'Year'
              : _selectedShelterDurationUnit == 'Months'
                  ? 'Month'
                  : 'Week')
          : _selectedShelterDurationUnit;

      // Save to Firestore
      await FirebaseFirestore.instance.collection('animals').add({
        'name': _nameController.text,
        'type': finalType,
        'age': age.toString(), // Store age as a string value
        'ageUnit': ageUnit, // Store the singular/plural unit
        'breed': _breedController.text,
        'gender': _selectedGender,
        'origin': _originController.text,
        'shelterDuration': shelterDuration.toString(), // Store duration as a string
        'shelterDurationUnit': shelterDurationUnit, // Store the singular/plural unit
        'organization': _organizationController.text,
        'pastExperience': _pastExperienceController.text,
        'medicalHistory': _medicalHistoryController.text,
        'spayed': _spayed,
        'vaccinated': _vaccinated,
        'vaccines': _selectedVaccines,
        'activityLevel': selectedActivity, // Storing the activity level
        'size': selectedSize, // Storing the size option
        'images': base64Images,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // Dismiss loading dialog

      // Reset the form after submission
      _clearForm();

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Pet added successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss success dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<List<String>> _processImagesForUpload() async {
    List<String> base64Images = [];
    for (var image in _images) {
      if (image != null) {
        List<int> imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add('data:image/jpeg;base64,$base64Image');
      }
    }
    return base64Images;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Pet profile has been successfully saved!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _breedController.clear();
    _otherTypeController.clear();
    _originController.clear();
    _shelterDurationController.clear();
    _pastExperienceController.clear();
    _medicalHistoryController.clear();
    setState(() {
      _selectedType = 'Dog';
      _selectedGender = 'Male';
      _selectedAgeUnit = 'Years';
      _selectedShelterDurationUnit = 'Months';
      _spayed = false;
      _vaccinated = false;
      _selectedVaccines = [];
      _images = List.generate(5, (index) => null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _organizationController.dispose();
    _otherTypeController.dispose();
    _originController.dispose();
    _shelterDurationController.dispose();
    _pastExperienceController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }
}
