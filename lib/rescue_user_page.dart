import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RescueUserPage extends StatefulWidget {
  const RescueUserPage({super.key});

  @override
  _RescueUserPageState createState() => _RescueUserPageState();
}

class _RescueUserPageState extends State<RescueUserPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  String? animalType,
      specificAnimalType,
      description,
      contact,
      addressText,
      location;
  XFile? image;
  Position? currentPosition;
  bool isLoadingLocation = false;
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();
  final specificAnimalTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Rescue a Pet Today!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Help rescue pets and give them a chance of life.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 60),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final scale =
                      1 + (_animationController.value * 0.1); // Scale effect
                  return MouseRegion(
                    cursor: SystemMouseCursors
                        .click, // Changes the cursor to a hand
                    child: GestureDetector(
                      onTap: () =>
                          _showRescueFormDialog(context), // Handle tap gesture
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepOrangeAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrangeAccent.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          width: 180,
                          height: 180,
                          alignment: Alignment.center,
                          child: Text(
                            'RESCUE NOW',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
      BuildContext context, ImageSource source, StateSetter setState) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        image = pickedFile;
      });
    }
  }

  Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
    } catch (e) {
      return '${position.latitude}, ${position.longitude}';
    }
  }

  void _resetForm() {
    setState(() {
      animalType = null;
      specificAnimalType = null;
      description = null;
      contact = null;
      addressText = null;
      location = null;
      image = null;
      currentPosition = null;
      isLoadingLocation = false;

      descriptionController.clear();
      contactController.clear();
      locationController.clear();
      specificAnimalTypeController.clear();
    });
  }
Future<String?> _uploadImageToFirebase(XFile image) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child('rescue_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(File(image.path));
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL(); // Return the image's download URL
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image upload failed: $e')),
    );
    return null;
  }
}

void _submitForm(BuildContext context, StateSetter setState) async {
  if (_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitting rescue details...')),
    );

    String? imageUrl;
    if (image != null) {
      imageUrl = await _uploadImageToFirebase(image!); // Upload the image
    }

    if (currentPosition != null) {
      try {
        await FirebaseFirestore.instance.collection('rescue_details').add({
          'animal_type': animalType,
          'specific_animal_type': specificAnimalType,
          'description': description,
          'contact': contact,
          'location': addressText,
          'latitude': currentPosition!.latitude,
          'longitude': currentPosition!.longitude,
          'image_url': imageUrl ?? '', // Store the image URL in Firestore
          'timestamp': FieldValue.serverTimestamp(),
          'rescue_status': 'Pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rescue details submitted successfully!')),
        );

        _resetForm(); // Reset the form for the next entry
        Navigator.of(context).pop(); // Close the form dialog
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rescue details: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current position is not available.')),
      );
    }
  }
}

  void _showRescueFormDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: screenHeight * 0.85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Sticky Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pets,
                            size: 32,
                            color: Colors.deepOrangeAccent,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Rescue Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please fill in the details below',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BASIC INFORMATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Animal Type Dropdown
                              _buildDropdownField(
                                label: 'Animal Type',
                                items: ['Dog', 'Cat'],
                                value: animalType,
                                onChanged: (value) {
                                  setState(() {
                                    animalType = value;
                                    if (value != 'Other') {
                                      specificAnimalType = null;
                                      specificAnimalTypeController.clear();
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an animal type';
                                  }
                                  return null;
                                },
                              ),

                              if (animalType == 'Other') ...[
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: specificAnimalTypeController,
                                  label: 'Specify Animal Type',
                                  onChanged: (value) =>
                                      specificAnimalType = value,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please specify the animal type.';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              SizedBox(height: 24),
                              Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Description Field
                              _buildTextField(
                                controller: descriptionController,
                                label: 'Description',
                                maxLines: 3,
                                onChanged: (value) => description = value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description.';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 24),
                              Text(
                                'CONTACT & LOCATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Contact Field
                              _buildTextField(
                                controller: contactController,
                                label: 'Contact Number',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      11),
                                ],
                                onChanged: (value) => contact = value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your contact information.';
                                  }
                                  if (value.length != 11) {
                                    return 'Contact number must be 11 digits.';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16),
                              _buildLocationField(setState),

                              SizedBox(height: 24),
                              Text(
                                'PHOTO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Image Upload Button
                              InkWell(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (BuildContext context) {
                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.all(8),
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          ListTile(
                                            leading: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.deepOrange[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.photo_library,
                                                  color:
                                                      Colors.deepOrangeAccent),
                                            ),
                                            title: Text('Upload from Gallery'),
                                            subtitle: Text(
                                                'Choose an existing photo'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage(
                                                  context,
                                                  ImageSource.gallery,
                                                  setState);
                                            },
                                          ),
                                          ListTile(
                                            leading: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.deepOrange[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.camera_alt,
                                                  color:
                                                      Colors.deepOrangeAccent),
                                            ),
                                            title: Text('Take a Photo'),
                                            subtitle: Text('Use your camera'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage(context,
                                                  ImageSource.camera, setState);
                                            },
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrangeAccent
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.deepOrangeAccent
                                            .withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          color: Colors.deepOrangeAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: Colors.deepOrangeAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 16),
                              // Image Status
                              image != null
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green[300]!),
                                      ),
                                      padding: EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green[600]),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Image selected: ${image!.name}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      padding: EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.image_not_supported,
                                              color: Colors.grey[600]),
                                          SizedBox(width: 8),
                                          Text(
                                            'No image selected',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sticky Footer with Action Buttons
                  Container(
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                // Reset all form fields and variables
                                animalType = null;
                                specificAnimalType = null;
                                specificAnimalTypeController.clear();
                                descriptionController.clear();
                                contactController.clear();
                                image = null;
                                location = null;
                                locationController.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitForm(context, setState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrangeAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit',
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
                ],
              ),
            );
          },
        );
      },
    );
  }

// This function shows the bottom sheet for selecting image source

  Widget _buildLocationField(StateSetter setState) {
    return InkWell(
      onTap: () async {
        bool serviceEnabled;
        LocationPermission permission;

        // Check if location services are enabled
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enable location services')),
          );
          return;
        }

        // Check location permission
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location permission is required')),
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Location permissions are permanently denied')),
          );
          return;
        }

        setState(() {
          isLoadingLocation = true;
        });

        try {
          // Get precise location
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 30),
          );

          // Get address from coordinates
          final address = await getAddressFromLatLng(position);

          setState(() {
            currentPosition = position;
            location = '${position.latitude}, ${position.longitude}';
            addressText = address;
            locationController.text = address;
            isLoadingLocation = false;
          });

          // Show map with current location
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            LatLng(position.latitude, position.longitude),
                        initialZoom:
                            18, // Increased zoom level for better detail
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40,
                              height: 40,
                              point:
                                  LatLng(position.latitude, position.longitude),
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      addressText ?? 'Location not available',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get location: $e')),
          );
          setState(() {
            isLoadingLocation = false;
          });
        }
      },
      child: TextFormField(
        controller: locationController,
        enabled: false,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Location',
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: isLoadingLocation
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.location_on),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a location';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
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
          borderSide: BorderSide(color: Colors.deepOrangeAccent),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600], // Set label color to white
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepOrangeAccent),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      value: value,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }
}
