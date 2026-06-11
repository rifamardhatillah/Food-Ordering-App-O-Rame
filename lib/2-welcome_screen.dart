import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '3-signin_screen.dart';
import '4-login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Image.asset(
                'image/welcome.png',
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20), // ✅ Padding dipindah ke sini
              decoration: BoxDecoration(
                color: Color(0xFFF9D33C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 29,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: 'Enjoy Instant '),
                        TextSpan(
                          text: 'Delivery',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          'Register',
                          Colors.white,
                          Colors.black,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignInScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _buildButton(
                          'Login',
                          Colors.white,
                          Colors.black,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 50),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: TextStyle(fontSize: 18),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Center(
          child: Text(text),
        ),
      ),
    );
  }
}
