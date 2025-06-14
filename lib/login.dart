import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawguard/forgot_password.dart';
import 'package:pawguard/organization_home.dart';
import 'package:pawguard/signup.dart';
import 'package:pawguard/user_home.dart';
import 'package:pawguard/matching_preferences.dart'; // Import the new screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _loadingController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _setupInitialAnimations();
  }

  void _setupInitialAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _headerOpacity = 1.0;
        _formOpacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  double _headerOpacity = 0.0;
  double _formOpacity = 0.0;

  Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  // Client-side validation
  if (email.isEmpty || password.isEmpty) {
    _showStyledMessageDialog(
      title: 'Missing Information',
      message: 'Please fill in both your email and password to log in.',
      isError: true,
    );
    return;
  }

  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    _showStyledMessageDialog(
      title: 'Invalid Email',
      message: 'Please enter a valid email address.',
      isError: true,
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Check if email is verified
    if (!userCredential.user!.emailVerified) {
      await FirebaseAuth.instance.signOut();
      _showStyledMessageDialog(
        title: 'Email Not Verified',
        message: 'Please verify your email before logging in.',
        isError: true,
      );
      setState(() => _isLoading = false);
      return;
    }

    // Fetch user data to determine their role
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user?.uid)
        .get();

    if (userDoc.exists) {
      String userRole = userDoc['role'] ?? '';

      // Redirect to the appropriate screen based on user role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => userRole == 'Individual'
              ? const MatchingPreferencesScreen()
              : const OrganizationHome(),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No account found for this email.';
        break;
      case 'wrong-password':
        errorMessage = 'The password you entered is incorrect.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address you entered is invalid.';
        break;
      default:
        errorMessage = e.message ?? 'An error occurred during login.';
    }

    _showStyledMessageDialog(
      title: 'Login Failed',
      message: errorMessage,
      isError: true,
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _showStyledMessageDialog(
        title: 'Reset Email Sent',
        message:
            'A password reset email has been sent to $email. Please check your inbox.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred. Please try again.';
      }

      _showStyledMessageDialog(
        title: 'Reset Failed',
        message: errorMessage,
        isError: true,
      );
    }
  }


  void _showStyledMessageDialog({
    required String title,
    required String message,
    required bool isError,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: isError ? Colors.red[100] : Colors.green[100],
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.red : Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onConfirm != null) {
                    onConfirm();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.red : Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildLoginForm(),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                      const SizedBox(height: 24),
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedOpacity(
      opacity: _headerOpacity,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      child: Column(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Image.asset(
                'assets/splash_logo.png',
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF6B39),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue helping animals in need',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
  return AnimatedOpacity(
    opacity: _formOpacity,
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeOut,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          prefix: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          prefix: Icons.lock_outline,
          errorText: _passwordError,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4), // Minimal spacing between Password and Forgot Password
          child: Align(
            alignment: Alignment.centerRight, // Align to the right
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Remove default padding
                foregroundColor: const Color(0xFFEF6B39), // Orange color
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData prefix,
  bool isPassword = false,
  TextInputType? keyboardType,
  String? errorText,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorText != null ? Colors.red : Colors.grey[300]!,
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: errorText != null ? Colors.red : Colors.grey[600],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefix,
              color: errorText != null ? Colors.red : const Color(0xFFEF6B39),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFEF6B39),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}



  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF6B39),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        _isLoading ? 'Logging in...' : 'Login',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFEF6B39),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
