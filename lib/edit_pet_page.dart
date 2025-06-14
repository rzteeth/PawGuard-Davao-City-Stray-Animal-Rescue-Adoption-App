import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class EditPetPage extends StatefulWidget {
  final String petId;
  final Map<String, dynamic> petData;

  const EditPetPage({required this.petId, required this.petData, Key? key})
      : super(key: key);

  @override
  _EditPetPageState createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _breedController;
  late TextEditingController _organizationController;
  late TextEditingController _otherTypeController;
  late TextEditingController _originController;
  late TextEditingController _shelterDurationController;
  late TextEditingController _pastExperienceController;
  late TextEditingController _medicalHistoryController;
  
  String _selectedGender = 'Male'; // Default value for Gender
  String _selectedAgeUnit = 'Years'; // Default value for Age Unit (non-nullable)
  String _selectedType = 'Dog'; // Default value for Pet Type
  String? _selectedActivity;
  String? _selectedSize;

  bool _spayed = false;
  bool _vaccinated = false;
  List<String> _selectedVaccines = [];
  List<File?> _images = List.generate(5, (index) => null);

  final picker = ImagePicker();
  final List<String> activityOptions = ['Playful', 'Calm', 'Energetic', 'Loving'];
  final List<String> sizeOptions = ['Small', 'Medium', 'Large'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.petData['name']);
    _ageController = TextEditingController(text: widget.petData['age']?.toString() ?? '');
    _breedController = TextEditingController(text: widget.petData['breed']);
    _organizationController = TextEditingController(text: widget.petData['organization']);
    _otherTypeController = TextEditingController(text: widget.petData['type'] == 'Other' ? widget.petData['otherType'] : '');
    _originController = TextEditingController(text: widget.petData['origin']);
    _shelterDurationController = TextEditingController(text: widget.petData['shelterDuration']?.toString() ?? '');
    _pastExperienceController = TextEditingController(text: widget.petData['pastExperience']);
    _medicalHistoryController = TextEditingController(text: widget.petData['medicalHistory']);
    _selectedGender = widget.petData['gender'];
    _selectedType = widget.petData['type'];
    _selectedActivity = widget.petData['activity'];
    _selectedSize = widget.petData['size'];
    _spayed = widget.petData['spayed'] ?? false;
    _vaccinated = widget.petData['vaccinated'] ?? false;
    _selectedVaccines = List<String>.from(widget.petData['vaccines'] ?? []);
    if (widget.petData['images'] != null && widget.petData['images'].isNotEmpty) {
      _images[0] = File(widget.petData['images'][0]);
    }
  }

  // Dropdown button for Age Unit selection
  Widget _buildDropdownField(String label, String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,  // No longer null, always have a valid value
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  // Method to pick image from gallery
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

  // Update pet data
  Future<void> _updatePet() async {
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

        final List<String> base64Images = await _processImagesForUpload();
        String finalType = _selectedType == 'Other' ? _otherTypeController.text : _selectedType!;

        await FirebaseFirestore.instance.collection('animals').doc(widget.petId).update({
          'name': _nameController.text,
          'breed': _breedController.text,
          'activity': _selectedActivity,
          'size': _selectedSize,
          'type': finalType,
          'gender': _selectedGender,
          'age': _ageController.text,
          'ageUnit': _selectedAgeUnit,
          'origin': _originController.text,
          'shelterDuration': _shelterDurationController.text,
          'pastExperience': _pastExperienceController.text,
          'medicalHistory': _medicalHistoryController.text,
          'spayed': _spayed,
          'vaccinated': _vaccinated,
          'vaccines': _selectedVaccines,
          'images': base64Images,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).pop(); // Dismiss loading dialog

        // Reset the form
        _clearForm();

        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Pet details updated successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss success dialog

                    // Navigate to Manage Pets Page
                    Navigator.pop(context); // Close the edit page
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

  // Clear form fields
  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _breedController.clear();
    _organizationController.clear();
    _otherTypeController.clear();
    _originController.clear();
    _shelterDurationController.clear();
    _pastExperienceController.clear();
    _medicalHistoryController.clear();
    setState(() {
      _selectedType = 'Dog';
      _selectedGender = 'Male';
      _selectedAgeUnit = 'Years';
      _selectedActivity = null;
      _selectedSize = null;
      _spayed = false;
      _vaccinated = false;
      _selectedVaccines = [];
      _images = List.generate(5, (index) => null);
    });
  }

  // Dispose controllers
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

  // Build Image section
  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: () => _pickImage(0), // Pick first image
            ),
            // Show first image if available
            if (_images[0] != null) ...[
              Image.file(_images[0]!, width: 100, height: 100),
            ]
          ],
        ),
      ),
    );
  }

  // Build text field for common fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }

  // Build activity buttons
  Widget _buildActivityButtons() {
    return Wrap(
      spacing: 8.0,
      children: activityOptions.map((option) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedActivity == option ? Colors.orange : Colors.white,
            foregroundColor: _selectedActivity == option ? Colors.white : Colors.black,
          ),
          onPressed: () {
            setState(() {
              _selectedActivity = option;
            });
          },
          child: Text(option),
        );
      }).toList(),
    );
  }

  // Build size buttons
  Widget _buildSizeButtons() {
    return Wrap(
      spacing: 8.0,
      children: sizeOptions.map((option) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedSize == option ? Colors.orange : Colors.white,
            foregroundColor: _selectedSize == option ? Colors.white : Colors.black,
          ),
          onPressed: () {
            setState(() {
              _selectedSize = option;
            });
          },
          child: Text(option),
        );
      }).toList(),
    );
  }

  // Submit button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _updatePet,
      child: const Text('Update Pet'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pet'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image section
              _buildImageSection(),
              // Name field
              _buildTextField(controller: _nameController, label: 'Pet Name', icon: Icons.pets),
              // Breed field
              _buildTextField(controller: _breedController, label: 'Breed', icon: Icons.pets_outlined),
              // Age section
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(controller: _ageController, label: 'Age', icon: Icons.calendar_today, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdownField('Unit', _selectedAgeUnit, ['Years', 'Months'], (value) => setState(() => _selectedAgeUnit = value!))),
                ],
              ),
              // Activity level buttons
              _buildActivityButtons(),
              // Size buttons
              _buildSizeButtons(),
              // Other details fields
              _buildTextField(controller: _originController, label: 'Origin', icon: Icons.location_history),
              _buildTextField(controller: _shelterDurationController, label: 'Time in Shelter', icon: Icons.timer),
              _buildTextField(controller: _pastExperienceController, label: 'Past Experience', icon: Icons.history_edu),
              _buildTextField(controller: _medicalHistoryController, label: 'Medical History', icon: Icons.medical_services_outlined),
              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}
