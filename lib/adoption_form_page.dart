import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'thank_you_page.dart';

class AdoptionFormPage extends StatefulWidget {
  final String animalId;
  final String organizationId;

  const AdoptionFormPage(
      {Key? key, required this.animalId, required this.organizationId})
      : super(key: key);

  @override
  _AdoptionFormPageState createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends State<AdoptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFileName;
  File? _selectedFile;
  bool _isLoading = false;

  final List<String> _petTypes = ['Dog', 'Cat'];

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _adoptReasonController = TextEditingController();
  final _existingPetsController = TextEditingController();
  final _incomeController = TextEditingController();
  final _numberOfPetsController = TextEditingController();

  String _existingPetsAnswer = 'No';
  String? _selectedPetType;
  List<String> _selectedPetTypes = [];

  @override
  void dispose() {
    _numberOfPetsController.dispose();
    _incomeController.dispose();
    _existingPetsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image != null) {
        setState(() {
          _selectedFileName = image.name;
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error picking file. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
  if (_formKey.currentState!.validate() && _selectedFile != null) {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Please sign in to submit an application');
      }

      // 2. Upload image to Firebase Storage
      final String fileName = 'adoption_applications/${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(_selectedFile!);
      final String imageUrl = await uploadTask.ref.getDownloadURL();

      // 3. Prepare Application Data
      final Map<String, dynamic> applicationData = {
        'userId': currentUser.uid,
        'animalId': widget.animalId,
        'organizationId': widget.organizationId,
        'status': 'pending',
        'submissionDate': Timestamp.now(),
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'adoptionReason': _adoptReasonController.text.trim(),
        'existingPets': _existingPetsAnswer, // "Do you have any existing pets?" response
        'governmentIdImageUrl': imageUrl, // Save the image URL
        'lastUpdated': Timestamp.now(),
        'monthlyIncome': _incomeController.text.trim(), 
      };

      // Add pet-specific data if "Yes" is selected for "Do you have any existing pets?"
      if (_existingPetsAnswer == 'Yes') {
        applicationData['existingPetType'] = _selectedPetType; // Single selected pet type
        applicationData['existingPetCount'] = _numberOfPetsController.text.trim(); // Number of pets
      }

      // 4. Save to Firestore
      await FirebaseFirestore.instance
          .collection('adoption_applications')
          .add(applicationData)
          .then((docRef) async {
        // Update animal status
        try {
          await FirebaseFirestore.instance
              .collection('animals')
              .doc(widget.animalId)
              .update({
            'adoptionStatus': 'pending',
            'currentApplicationId': docRef.id,
            'lastUpdated': Timestamp.now(),
          });
        } catch (e) {
          print('Error updating animal status: $e');
          // Continue with success flow even if animal update fails
        }

        // Show success message
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessDialog();
        }
      });
    } catch (error) {
      print('Error during submission: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit the application. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete all fields and upload your ID'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

// Fetch user details from Firestore and populate controllers
  Future<void> _fetchUserDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user document from Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          // Populate the controllers with user data
          setState(() {
            _nameController.text = data['name'] ?? 'Full Name Not Found';
            _emailController.text = data['email'] ?? 'Email Not Found';
            _phoneController.text = data['phone'] ?? 'Phone Not Found';
            _addressController.text = data['address'] ?? 'Address Not Found';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user details: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 48, color: Color(0xFFEF6B39)),
                const SizedBox(height: 16),
                const Text(
                  'Application Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF6B39),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your adoption application has been successfully submitted.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThankYouPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6B39),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false, // Add the readOnly parameter (default: false)
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFFEF6B39))
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF6B39), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: validator,
        inputFormatters: inputFormatters,
        readOnly: readOnly, // Use the readOnly parameter here
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Adoption Form',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEF6B39),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF6B39),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: const Text(
                  'Please fill in your details to proceed with the adoption',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Personal Information'),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person,
                            readOnly: true, // Make the field read-only
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email,
                            readOnly: true, // Make the field read-only
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email address is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone,
                            readOnly: true, // Make the field read-only
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (value.length != 11) {
                                return 'Phone number must be 11 digits';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Home Address',
                            hint: 'Enter your complete address',
                            maxLines: 3,
                            prefixIcon: Icons.home,
                            readOnly: true, // Make the field read-only
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Home address is required';
                              }
                              return null;
                            },
                          ),
                          _buildSectionTitle('Additional Information'),
                          _buildTextField(
                            controller: _adoptReasonController,
                            label: 'Why do you want to adopt?',
                            hint: 'Share your reasons for adopting a pet',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please share your reasons for adoption';
                              }
                              return null;
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Align items to the left
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  'Do you have any existing pets?',
                                  style: TextStyle(
                                    fontSize: 14, // Smaller font size
                                    fontWeight: FontWeight
                                        .normal, // Remove bold styling
                                    color: Colors
                                        .black87, // Optional: Customize color
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _existingPetsAnswer = 'Yes';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _existingPetsAnswer == 'Yes'
                                              ? const Color(0xFFEF6B39)
                                              : Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Yes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 20), // Space between buttons
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _existingPetsAnswer = 'No';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _existingPetsAnswer == 'No'
                                              ? const Color(0xFFEF6B39)
                                              : Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'No',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_existingPetsAnswer == 'Yes') ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'What type of pet(s) do you have?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0, // Space between buttons
                                  runSpacing:
                                      8.0, // Space between rows of buttons
                                  children: _petTypes.map((type) {
                                    final isSelected = _selectedPetType ==
                                        type; // Check if the type is selected
                                    return ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedPetType =
                                                null; // Deselect the pet type if already selected
                                          } else {
                                            _selectedPetType =
                                                type; // Select the pet type
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? const Color(
                                                0xFFEF6B39) // Highlight selected button
                                            : Colors.grey[
                                                300], // Default button color
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : const Color.fromARGB(255, 255, 255, 255), // Text color
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(type),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'How many pet(s) do you have?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller:
                                      _numberOfPetsController, // Use the new controller here
                                  label: 'Number of Pets',
                                  hint: 'E.g., 1, 2, 3',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please specify how many pet(s) you have';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller:
                                _incomeController, // Still using the income controller here
                            label: 'Work/Monthly Income',
                            hint:
                                'Provide your current occupation & monthly income',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please provide your income details';
                              }
                              return null;
                            },
                          ),
                          _buildSectionTitle('Government ID Upload'),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload your Valid Government ID',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accepted formats: JPG or PNG',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _selectedFileName ?? 'No file chosen',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(
                                        Icons.upload_file,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Choose File',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFEF6B39),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFEF6B39)),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFFEF6B39),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF6B39),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedFile != null
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  _submitForm();
                                }
                              }
                            : null,
                        child: !_isLoading
                            ? const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFEF6B39),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
