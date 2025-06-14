import 'package:flutter/material.dart';
import 'login_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Total duration of the animation
      vsync: this,
    );

    // Set up the bounce animation for the logo
    _bounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Bounce effect for more pronounced bounce
    );

    // Fade animation for the logo to make it fade after bounce
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: Curves.easeInOut), // Fade out after bounce completes
      ),
    );

    // Background fill animation to change the screen color smoothly
    _backgroundAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut), // Start immediately
      ),
    );

    // Start the bounce animation for the logo
    _controller.forward();

    // Navigate to the LoginSplashScreen when the animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginSplashScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the animation controller to free up resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Radial gradient fill animation
              AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: _backgroundAnimation.value,
                        colors: [Color(0xFFEF6B39), Colors.white],
                        stops: [0, 2],
                      ),
                    ),
                  );
                },
              ),

              // Logo animation with bounce and fade effect
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 100 * (1 - _bounceAnimation.value)), // Adjusted bounce height
                    child: child, // The logo image
                  ),
                ),
              ),
            ],
          );
        },
        child: Image.asset('assets/splash_logo.png', width: 250), // Your logo path
      ),
    );
  }
}
