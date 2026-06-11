import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '2-welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '5-home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCATPps-IL2heR7NqPcNNOC0F0Y_hZ6bZI",
      authDomain: "uas-salaya.firebaseapp.com",
      projectId: "uas-salaya",
      storageBucket: "uas-salaya.firebasestorage.app",
      messagingSenderId: "455902212910",
      appId: "1:455902212910:web:a94f040a1b805a499240bf",
      measurementId: 'G-GTTMD9PKGC',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "O'Rame Online Store",
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.amber,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3));
    
    final user = FirebaseAuth.instance.currentUser;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => user != null 
            ? HomeScreen(
                name: user.displayName ?? 'User',
                email: user.email ?? '',
              )
            : WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9D33C),
      body: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Image.asset('image/logo.png', width: 120),
        ),
      ),
    );
  }
}