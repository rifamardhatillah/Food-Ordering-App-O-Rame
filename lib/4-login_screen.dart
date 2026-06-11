import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '3-signin_screen.dart'; 
import '5-home_screen.dart';   
import 'firebase_service.dart'; 
import '10-password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Membuat instance dari service kustom yang akan menangani logika Google Sign-In.
  // Ini membantu menjaga kode di layar ini tetap bersih dan fokus pada UI.
  final FirebaseService _firebaseService = FirebaseService(); 
  
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return; 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // --- PENJELASAN PROSES LOGIN DENGAN EMAIL & PASSWORD ---
  Future<void> _loginWithEmail() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Email dan password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. MEMANGGIL FIREBASE: 
      //    'FirebaseAuth.instance' adalah objek utama untuk semua operasi autentikasi.
      //    'signInWithEmailAndPassword' adalah fungsi yang mengirimkan email dan password 
      //    ke server Firebase untuk diverifikasi secara aman.
      //    'await' digunakan karena proses ini butuh koneksi internet dan waktu, jadi
      //    aplikasi akan menunggu sampai Firebase memberikan jawaban (berhasil atau gagal).
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (!mounted) return;

      // 2. JIKA BERHASIL:
      //    Firebase akan mengembalikan objek 'UserCredential' yang berisi info user.
      //    Firebase juga secara otomatis menyimpan status login pengguna di perangkat,
      //    sehingga saat aplikasi dibuka lagi, pengguna tetap dalam keadaan login.
      _showSuccessSnackBar("Login Berhasil!"); 
      
      String userName = userCredential.user?.displayName ?? userCredential.user?.email?.split('@').first ?? 'User';
      String userEmail = userCredential.user?.email ?? 'Tidak ada email';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            name: userName,
            email: userEmail,
            cart: [], 
            orderHistory: [], 
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {
      // 3. JIKA GAGAL (ERROR DARI FIREBASE):
      //    Blok ini khusus menangani error yang sudah dikenali oleh Firebase.
      //    Objek 'e' berisi kode error ('e.code') yang sangat spesifik, memungkinkan kita
      //    memberikan pesan error yang lebih baik kepada pengguna.
      String errorMessage = "Terjadi kesalahan saat login";
      
      // Contoh penanganan kode error spesifik dari Firebase:
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = "Email belum terdaftar";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Password salah";
      } else if (e.code == 'invalid-credential' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        // Ini adalah kode error modern dari Firebase yang tidak membedakan antara
        // email salah atau password salah demi keamanan.
        errorMessage = "Email atau password salah.";
      }
      if (mounted) _showErrorSnackBar(errorMessage);

    } catch (e) {
      // 4. JIKA GAGAL (ERROR UMUM):
      //    Menangani error lain yang mungkin terjadi, seperti tidak ada koneksi internet.
      if (mounted) _showErrorSnackBar("Terjadi kesalahan: ${e.toString()}");

    } finally {
      // 5. BLOK FINAL:
      //    Akan selalu dieksekusi baik login berhasil maupun gagal.
      //    Sangat penting untuk menghentikan indikator loading.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // --- PENJELASAN PROSES LOGIN DENGAN GOOGLE ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. MENDELEGASIKAN TUGAS KE SERVICE:
      //    Kita tidak menulis logika kompleks login Google di sini. Sebagai gantinya,
      //    kita memanggil satu fungsi dari 'FirebaseService' yang sudah kita buat.
      User? user = await _firebaseService.signInWithGoogle(); 
      
      // DI DALAM `firebase_service.dart`, prosesnya adalah:
      // a. Memunculkan pop-up pilihan akun Google.
      // b. Mendapatkan token autentikasi dari Google setelah user memilih akun.
      // c. Menukar token Google tersebut dengan Kredensial Firebase.
      // d. Memanggil `FirebaseAuth.instance.signInWithCredential(credential)` untuk
      //    masuk ke Firebase menggunakan akun Google tersebut.
      // e. Mengembalikan objek 'User' jika berhasil, atau 'null' jika dibatalkan.

      if (!mounted) return;

      if (user != null) {
        // 2. JIKA BERHASIL:
        //    Service mengembalikan objek 'User' yang valid. Firebase kini mengelola sesi login.
        _showSuccessSnackBar("Login Google Berhasil!");

        String userName = user.displayName ?? user.email?.split('@').first ?? 'User';
        String userEmail = user.email ?? 'Tidak ada email'; 
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              name: userName,
              email: userEmail,
              cart: [], 
              orderHistory: [], 
            ),
          ),
        );
      } else {
        // 3. JIKA GAGAL ATAU DIBATALKAN:
        //    Service mengembalikan 'null', misalnya jika pengguna menutup pop-up pilihan akun.
        if (mounted) _showErrorSnackBar("Login Google gagal atau dibatalkan oleh pengguna.");
      }
    } catch (e) { 
      // 4. MENANGANI ERROR:
      //    Menangkap error yang mungkin dilempar oleh service, misalnya jika ada
      //    masalah koneksi atau konfigurasi Firebase/Google yang salah.
      if (mounted) {
        _showErrorSnackBar("Terjadi kesalahan saat login dengan Google: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9D33C),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Bagian UI Atas ---
             SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: _isLoading ? null : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text("Login", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    SizedBox(height: 5),
                    Text("Silakan masuk untuk mengakses akun dan melanjutkan transaksi Anda!", style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Inter')),
                  ],
                ),
              ),
            ),
            SizedBox(height: 50),

            // --- Bagian Form Input ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    buildTextField("Email", Icons.email, emailController),
                    SizedBox(height: 18),
                    buildTextField("Password", Icons.lock, passwordController, obscureText: true),
                    SizedBox(height: 15),
                    
                    // --- PENJELASAN ALUR LUPA PASSWORD ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading 
                            ? null 
                            : () {
                                // 1. INISIASI ALUR RESET PASSWORD:
                                //    Tombol ini tidak langsung memanggil fungsi Firebase.
                                //    Tugasnya adalah mengarahkan pengguna ke layar khusus
                                //    untuk proses reset password.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PasswordResetScreen()),
                                );
                                // 2. PROSES FIREBASE TERJADI DI LAYAR BERIKUTNYA:
                                //    Di dalam 'PasswordResetScreen.dart', akan ada tombol yang
                                //    memanggil `FirebaseAuth.instance.sendPasswordResetEmail()`.
                              },
                        child: Text(
                          "Lupa Password?",
                          style: TextStyle(color: Color(0xFFF9D33C), fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Tombol Login dengan Email
                     ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithEmail, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        minimumSize: Size(double.infinity, 60),
                      ),
                      child: _isLoading 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Inter')),
                    ),
                    SizedBox(height: 25),
                    
                    // Link ke Halaman Registrasi
                    GestureDetector(
                      onTap: _isLoading ? null : () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignInScreen()));
                      },
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Belum memiliki akun? ",
                            style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Inter'),
                            children: [
                              TextSpan(text: "Register", style: TextStyle(color: Color(0xFFF9D33C), fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Tombol Login dengan Google
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, 
                        foregroundColor: Colors.black, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.grey.shade300)),
                        padding: EdgeInsets.symmetric(vertical: 15), 
                        minimumSize: Size(double.infinity, 60),
                      ),
                      child: _isLoading 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('image/google.png', height: 24, errorBuilder: (context, error, stackTrace) => Icon(Icons.login, color: Colors.red)),
                                SizedBox(width: 12), 
                                Text("Login dengan Google", style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Inter')),
                              ],
                            ),
                    ),
                    SizedBox(height: 20), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat TextField, tidak ada interaksi Firebase di sini.
  Widget buildTextField(String label, IconData icon, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: !_isLoading, 
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            hintText: "Masukkan $label Anda", 
            hintStyle: TextStyle(color: Colors.black38, fontFamily: 'Inter', fontSize: 14),
            floatingLabelBehavior: FloatingLabelBehavior.never, 
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
             focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Color(0xFFF9D33C), width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}