import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PersonalInfoPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PersonalInfoPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late Map<String, dynamic> _userData;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _image;
  bool isLoading = false;
  bool _isFormChanged = false;
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;

  // Design Constants
  final Color primaryColor = const Color(0xFFEF6B39); // Example brand color
  final Color secondaryColor =
      const Color(0xFFFAFAFA); // Lighter background color for contrast
  final Color textColor = const Color(0xFF333333); // Standard text color
  final Color subtextColor = const Color(0xFF6B7280);
  final Color errorColor = const Color(0xFFDC3545);
  final Color successColor = const Color(0xFF28A745);
  final double borderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _nameController = TextEditingController(text: _userData['name'] ?? '');
    _emailController = TextEditingController(text: _userData['email'] ?? '');
    _phoneController = TextEditingController(text: _userData['phone'] ?? '');
    _addressController =
        TextEditingController(text: _userData['address'] ?? '');
    _nameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {
      _isFormChanged = _nameController.text.trim() != _userData['name'] ||
          _phoneController.text.trim() != _userData['phone'] ||
          _addressController.text.trim() != _userData['address'];
    });
  }

  Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return file;

      double maxWidth = 512.0;
      double maxHeight = 512.0;
      double ratio = math.min(maxWidth / image.width, maxHeight / image.height);
      final int targetWidth = (image.width * ratio).round();
      final int targetHeight = (image.height * ratio).round();

      final img.Image resizedImg = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      final compressedBytes = img.encodeJpg(resizedImg, quality: 85);
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg')
        ..writeAsBytesSync(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return file;
    }
  }

  Future<void> _showImagePickerModal() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Update Profile Picture',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildPickerOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  getImageFromGallery();
                },
              ),
              const SizedBox(height: 16),
              _buildPickerOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  getImageFromCamera();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getImageFromGallery() async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final imageBytes = await imageFile.readAsBytes();
        if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
          showSizeLimitDialog();
          return;
        }

        File compressedFile = await compressImage(imageFile);
        setState(() {
          _image = compressedFile;
          _isFormChanged = true;
        });
        await _showImagePreviewDialog(compressedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorColor,
            content: Text('Error picking image: ${e.toString()}'),
          ),
        );
      }
      print('Error picking image: $e');
    }
  }

  void showSizeLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Image Size Limit'),
        content: const Text('Please select an image smaller than 5MB.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> getImageFromCamera() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      File compressedFile = await compressImage(imageFile);

      setState(() {
        _image = compressedFile;
      });
      await _showImagePreviewDialog(compressedFile);
    }
  }

  Future<void> _showImagePreviewDialog(File imageFile) async {
    bool? shouldUpload = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Preview Image',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Image.file(
                    imageFile,
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                      child: const Text(
                        'Upload',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldUpload == true) {
      await _processImageUpload(imageFile);
    }
  }

  Future<void> _processImageUpload(File imageFile) async {
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'image': base64Image,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userData['image'] = base64Image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: successColor,
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile picture updated successfully!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorColor,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error updating profile picture: ${e.toString()}'),
              ],
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final updatedName = _nameController.text.trim();
      final updatedPhone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;
      final updatedAddress = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'name': updatedName,
        'phone': updatedPhone,
        'address': updatedAddress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userData['name'] = updatedName;
        _userData['phone'] = updatedPhone;
        _userData['address'] = updatedAddress;
        _isFormChanged = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: successColor,
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully!'),
              ],
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorColor,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error updating profile: ${e.toString()}'),
              ],
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFormChanged) {
          bool? shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => _buildDiscardDialog(),
          );
          return shouldDiscard ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            ),
            onPressed: () async {
              if (_isFormChanged) {
                bool? shouldDiscard = await showDialog<bool>(
                  context: context,
                  builder: (context) => _buildDiscardDialog(),
                );
                if (shouldDiscard ?? false) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileImage(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Form Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Personal Information',
                          'Update your profile information',
                        ),
                        const SizedBox(height: 30),
                        _buildFormField(
                          label: 'Full Name',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          hint: 'Enter your full name',
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Email Address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType:
                              TextInputType.phone, // Set the keyboard type here
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Address',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _userData['image'] != null
                ? Image.memory(
                    base64Decode(_userData['image']),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: secondaryColor,
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: subtextColor,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _showImagePickerModal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the label for required fields
        // (We are hiding the "Optional" part)
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : secondaryColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              color: enabled ? textColor : subtextColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint ?? '',
              hintStyle: TextStyle(
                color: subtextColor.withOpacity(0.5),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: enabled ? primaryColor : subtextColor,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _isFormChanged ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isFormChanged ? _updateUserInfo : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0,
          ),
          child: Text(
            'Save Changes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Updating Profile...',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscardDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: errorColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Discard Changes?',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your changes will be lost if you go back without saving.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: const Text(
                      'Discard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
