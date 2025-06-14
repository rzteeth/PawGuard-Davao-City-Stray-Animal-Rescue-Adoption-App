import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';

class LoginSplashScreen extends StatefulWidget {
  const LoginSplashScreen({super.key});

  @override
  _LoginSplashScreenState createState() => _LoginSplashScreenState();
}

class _LoginSplashScreenState extends State<LoginSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;
  int _currentPage = 0;
  late PageController _pageController;
   bool _isAnimating = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/splash1.jpg',
      'title': 'Give Love, Gain Joy',
      'subheading': 'Why Adopt a Pet?',
      'description':
          'Adopting a pet brings unconditional love, companionship, and the chance to save a life. Start your journey today.',
      'width': 330.0,
      'height': 350.0,
    },
    {
      'image': 'assets/splash4.jpg',
      'title': 'Find Your Best Friend',
      'subheading': 'A Perfect Match Awaits',
      'description':
          'Every pet deserves a loving home. Browse adorable profiles to find your ideal companion.',
      'width': 330.0,
      'height': 350.0,
    },
    {
      'image': 'assets/splash7.jpg',
      'title': 'Be Their Hero',
      'subheading': 'Change a Life Forever',
      'description':
          'Your decision to adopt gives a homeless pet a second chance at happiness and love.',
      'width': 330.0,
      'height': 350.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticInOut));
    _offsetAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.0), end: const Offset(0.0, -0.05))
        .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeInOutCubic));

    _pageController = PageController(initialPage: 0)..addListener(() {
          setState(() {});
        });
    Future.delayed(const Duration(seconds: 2), () {
      autoScroll();
    });
  }

  void autoScroll() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
      autoScroll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                double scale = 1.0;
                if (_pageController.position.haveDimensions) {
                  scale = 1 - (_pageController.page! - index).abs() * 0.3;
                  scale = scale.clamp(0.7, 1.0);
                }

                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _currentPage == index ? 1.0 : 0.7,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.translate(
                            offset: _offsetAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'splash_image_$index',
                                  child: Image.asset(
                                    _pages[index]['image']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),  SizedBox(height: 30),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: _currentPage == index ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF6B39),
                            ),
                            child: Text(_pages[index]['title']!),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _pages[index]['subheading']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              _pages[index]['description']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFFEF6B39)
                        : const Color(0xFFEF6B39).withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedButton(
                  label: 'Login',
                  isOutlined: false,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  ),
                ),
                _buildAnimatedButton(
                  label: 'Signup',
                  isOutlined: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String label,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: _isAnimating ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 140,
            height: 50,
            child: isOutlined
                ? OutlinedButton(
                    onPressed: () {
                      setState(() => _isAnimating = !_isAnimating);
                      onPressed();
                    },
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFFEF6B39), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFEF6B39),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() => _isAnimating = !_isAnimating);
                      onPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6B39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
