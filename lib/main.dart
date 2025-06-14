import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawguard/adopted_animals_page.dart';
import 'package:pawguard/login.dart';
import 'package:pawguard/notifications_page.dart';
import 'package:pawguard/personal_info.dart';
import 'package:pawguard/profile/applications.dart';
import 'package:pawguard/splash.dart';
import 'profile/about.dart';
import 'profile/events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    OnlineStatusManager(
      child: const PawGuardApp(),
    ),
  );
}

class PawGuardApp extends StatelessWidget {
  const PawGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawGuard',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: const Color(0xFFEF6B39),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEF6B39),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF6B39),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile/personal-info': (context) => PersonalInfoPage(
              userData: ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/profile/about': (context) => const AboutPage(),
        '/profile/applications': (context) => ApplicationsPage(
              organizationId: '',
            ),
        '/adoptedAnimals': (context) => const AdoptedAnimalsPage(),
        '/events': (context) => AddEventPage(
              organizerId: FirebaseAuth.instance.currentUser?.uid ?? '',
              organizationId: '',
            ),
        '/notifications': (context) => NotificationsPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class OnlineStatusManager extends StatefulWidget {
  final Widget child;

  const OnlineStatusManager({Key? key, required this.child}) : super(key: key);

  @override
  _OnlineStatusManagerState createState() => _OnlineStatusManagerState();
}

class _OnlineStatusManagerState extends State<OnlineStatusManager>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true); // Set user online when the app starts
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false); // Set user offline when the app is closed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true); // Online when the app is active
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnlineStatus(false); // Offline when the app is in the background or closed
    }
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isOnline': isOnline});
        debugPrint("User ${user.uid} is now ${isOnline ? 'online' : 'offline'}");
      }
    } catch (e) {
      debugPrint("Failed to update online status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
