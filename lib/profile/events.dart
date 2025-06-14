import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawguard/organization_home.dart';

class AddEventPage extends StatefulWidget {
  final String organizerId;
  const AddEventPage(
      {Key? key, required this.organizerId, required String organizationId})
      : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  File? _selectedImage;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFFEF6B39); // Orange theme color
  final Color secondaryColor = const Color(0xFF333333); // Dark grey for text
  final Color backgroundColor = Colors.grey[50]!; // Light background color

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog("Error selecting image");
    }
  }

  Future<String> _uploadImageToFirebase() async {
    if (_selectedImage == null) {
      return '';
    }

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('event_images/$fileName');

      await imageRef.putFile(_selectedImage!);
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return '';
    }
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final DateTime currentDate = DateTime.now();
    final DateTime lastSelectableDate = currentDate.add(Duration(days: 365));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: currentDate,
      lastDate: lastSelectableDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _endDate = _startDate.add(const Duration(hours: 1));
          } else {
            _endDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          }
        });
      }
    }
  }

  Future<void> _submitEvent() async {
  // Validate form fields
  List<String> missingFields = [];

  if (_titleController.text.trim().isEmpty) missingFields.add("Event Title");
  if (_descriptionController.text.trim().isEmpty) missingFields.add("Description");
  if (_locationController.text.trim().isEmpty) missingFields.add("Location");

  if (missingFields.isNotEmpty) {
    // Show a single error dialog listing all the missing fields
    _showMissingFieldsDialog(missingFields);
    return;
  }

  try {
    setState(() {
      _isLoading = true;  // Show loading state
    });

    String imageUrl = '';
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToFirebase();  // Upload image if selected
    }

    // Add event to Firestore
    await FirebaseFirestore.instance.collection('events').add({
      'organizerId': widget.organizerId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'startDate': Timestamp.fromDate(_startDate),
      'endDate': Timestamp.fromDate(_endDate),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    if (mounted) {
      setState(() {
        // Reset all form fields
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _startDate = DateTime.now();
        _endDate = DateTime.now().add(const Duration(hours: 1));
        _selectedImage = null;  // Clear selected image
      });

      // Reset the form validation state
      _formKey.currentState?.reset();

      // Show success dialog
      _showSuccessDialog("Event created successfully!");
    }
  } catch (error) {
    if (mounted) {
      // Show error dialog if creation fails
      _showErrorDialog("Failed to create event. Please try again.");
    }
  } finally {
    setState(() {
      _isLoading = false;  // Hide loading state
    });
  }
}

// Success Dialog Function
void _showSuccessDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Smooth rounded corners
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30), // Keep dialog narrow and centered
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green[50],  // Soft background for icon
                child: Icon(
                  Icons.check_circle_outline,  // Success icon
                  color: Colors.green,  // Icon color for success
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title Text (message heading)
              Text(
                "Success!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,  // Subtle dark color for title
                ),
              ),
              const SizedBox(height: 12),

              // Success Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,  // Lighter gray for the fields list
                  fontWeight: FontWeight.w400,
                  height: 1.5, // Line height for clarity
                ),
              ),
              const SizedBox(height: 24),

              // OK Button
              ElevatedButton(
                onPressed: () {
                  // Dismiss the success dialog
                  Navigator.of(context).pop();
                  // Navigate to OrganizationHome after dialog is closed
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => OrganizationHome()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,  // Success button color
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),  // Larger padding for a comfortable button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),  // Rounded button corners
                  ),
                  elevation: 5,  // Slight elevation for a floating effect
                  shadowColor: Colors.black.withOpacity(0.2),  // Soft shadow for depth
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 18,  // Larger font size for better readability
                    fontWeight: FontWeight.w600,  // Slightly bold text for emphasis
                    color: Colors.white,  // White text for contrast
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // Function to show a modern iOS-style dialog with improved button and warning icon design
  void _showMissingFieldsDialog(List<String> missingFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Smooth rounded corners
          ),
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 30), // Keep dialog narrow and centered
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern warning icon with CircleAvatar for elevation effect
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromARGB(
                      255, 255, 255, 255), // Soft background for icon
                  child: Icon(
                    Icons.warning_amber_outlined, // Subtle, modern warning icon
                    color: primaryColor, // Icon color matches the warning
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),

                // Title Text (message heading)
                Text(
                  "Please fill in the following:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w400, // Medium weight for a clean look
                    color: Colors.black54, // Subtle dark color for title
                  ),
                ),
                const SizedBox(height: 12),

                // List of missing fields
                Text(
                  missingFields.join("\n"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54, // Lighter gray for the fields list
                    fontWeight: FontWeight.w400, // Regular font weight
                    height: 1.5, // Line height for clarity
                  ),
                ),
                const SizedBox(height: 24),

                // Full-width action button with modern style
                SizedBox(
                  width: double.infinity, // Make the button span the full width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Button background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 10), // Adjusted padding for smaller height
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded button corners
                      ),
                      elevation: 5, // Slight elevation for a floating effect
                      shadowColor: Colors.black
                          .withOpacity(0.2), // Soft shadow for depth
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18, // Larger font size for better readability
                        fontWeight:
                            FontWeight.w600, // Slightly bold text for emphasis
                        color: Colors.white, // White text for contrast
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

  
  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required String fieldName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null; // We will handle field validation using the dialog
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Icon(
                icon,
                color: primaryColor,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                title: 'Event Title',
                controller: _titleController,
                hint: 'Enter the title of your event',
                icon: Icons.title,
                fieldName: 'title',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      title: 'Starts',
                      date: _startDate,
                      onTap: () => _selectDateTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimeField(
                      title: 'Ends',
                      date: _endDate,
                      onTap: () => _selectDateTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                title: 'Location',
                controller: _locationController,
                hint: 'Enter event location',
                icon: Icons.location_on_outlined,
                fieldName: 'location',
              ),
              const SizedBox(height: 24),
              _buildInputField(
                title: 'Description',
                controller: _descriptionController,
                hint: 'Describe your event',
                icon: Icons.description_outlined,
                maxLines: 4,
                fieldName: 'description',
              ),
              const SizedBox(height: 24),
              // Image upload section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        16), // Rounded corners for the container
                    border: Border.all(color: primaryColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _selectedImage == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: primaryColor,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Add Image',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image display with BoxFit.cover to fit the container
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  16), // Clip the image to the container's rounded corners
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit
                                    .cover, // Ensures the image fills the container area
                                width: double
                                    .infinity, // Ensures the image spans the width of the container
                                height: double
                                    .infinity, // Ensures the image spans the height of the container
                              ),
                            ),
                            // Remove button, only visible when an image is selected
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage =
                                        null; // Remove the image when tapped
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLoading ? 'Creating Event...' : 'Create Event',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
