// File: lib/custom_splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

class CustomSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const CustomSplashScreen({Key? key, required this.nextScreen})
      : super(key: key);

  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimationIcon;
  late Animation<double> _scaleAnimationIcon;
  late Animation<double> _fadeAnimationText;
  late Animation<Offset> _slideAnimationText; // Untuk animasi slide teks

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000), // Durasi animasi sedikit lebih lama
    );

    // Animasi untuk Ikon
    _scaleAnimationIcon = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut), // Efek elastis lebih terasa
      ),
    );
    _fadeAnimationIcon = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1, 0.7, curve: Curves.easeIn),
      ),
    );

    // Animasi untuk Teks
    _fadeAnimationText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn), // Teks muncul setelah ikon
      ),
    );
    _slideAnimationText = Tween<Offset>(
            begin: Offset(0, 0.5), end: Offset.zero) // Mulai dari bawah
        .animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic), // Efek slide yang halus
      ),
    );

    _animationController.forward();

    Timer(Duration(seconds: 4), () { // Total waktu splash screen tetap
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder( // Transisi halaman yang lebih halus
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Latar belakang gradasi
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFBEA), // Kuning sangat muda
              Colors.white,
              // Color(0xFFFFF176), // Kuning muda
              // Color(0xFFFFE082), // Kuning sedikit lebih tua
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.8] // Atur distribusi warna
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- Ikon Centang ---
              ScaleTransition(
                scale: _scaleAnimationIcon,
                child: FadeTransition(
                  opacity: _fadeAnimationIcon,
                  child: Container(
                    padding: EdgeInsets.all(30.0), // Padding sedikit lebih besar
                    decoration: BoxDecoration(
                      gradient: LinearGradient( // Gradasi pada lingkaran ikon
                        colors: [Color(0xFFFFE57F), Color(0xFFFFD100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.shade700.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 15, // Blur lebih lembut
                          offset: Offset(0, 6), // Bayangan sedikit ke bawah
                        ),
                         BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          spreadRadius: -5, // Inner glow tipis
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded, // Ikon yang berbeda, lebih modern
                      // Icons.check_rounded, // Atau tetap dengan yang lama
                      color: Colors.white,
                      size: 80.0, // Ukuran ikon lebih besar
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.0), // Jarak lebih besar

              // --- Teks Informasi ---
              SlideTransition(
                position: _slideAnimationText,
                child: FadeTransition(
                  opacity: _fadeAnimationText,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35.0),
                    child: Text(
                      "Pesanan Anda sedang kami proses!", // Teks bisa dipersingkat
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0, // Font lebih besar
                        color: Colors.grey[850],
                        fontWeight: FontWeight.w600, // Sedikit lebih tebal
                        height: 1.5,
                        letterSpacing: 0.5, // Sedikit spasi antar huruf
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15.0),
               SlideTransition( // Teks kedua (opsional)
                position: _slideAnimationText, // Bisa gunakan animasi yang sama atau beda interval
                child: FadeTransition(
                  opacity: _fadeAnimationText,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Text(
                      "Kami akan segera mengkonfirmasi melalui WhatsApp Anda.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60), // Beri ruang di bawah
            ],
          ),
        ),
      ),
    );
  }
}