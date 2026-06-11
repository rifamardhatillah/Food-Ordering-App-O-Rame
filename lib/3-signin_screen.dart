// Import library penting
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk autentikasi Firebase
import '4-login_screen.dart'; // File tujuan jika registrasi berhasil

// Widget SignInScreen adalah Stateful karena akan mengubah state (loading, error, input)
class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Controller untuk menangani input dari TextField
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Instance Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Untuk menampilkan status loading saat registrasi
  bool _isLoading = false;

  // Validasi email menggunakan regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Menampilkan error dalam bentuk SnackBar
  void _showErrorSnackBar(String message) {
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

  // Fungsi untuk registrasi ke Firebase
  Future<void> register() async {
    // Ambil data dari inputan pengguna
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Validasi field kosong
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar("Semua field harus diisi!");
      return;
    }

    // Validasi format email
    if (!_isValidEmail(email)) {
      _showErrorSnackBar("Format email tidak valid!");
      return;
    }

    // Validasi panjang password
    if (password.length < 4) {
      _showErrorSnackBar("Password minimal 4 karakter!");
      return;
    }

    // Validasi password cocok dengan konfirmasi
    if (password != confirmPassword) {
      _showErrorSnackBar("Password dan konfirmasi tidak sama!");
      return;
    }

    // Set loading true saat mulai proses
    setState(() => _isLoading = true);

    try {
      // =======================================
      // ========== PROSES FIREBASE ============
      // =======================================

      // Registrasi user ke Firebase Authentication
      // Menggunakan email dan password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set nama pengguna ke akun Firebase (opsional tapi penting)
      await userCredential.user?.updateDisplayName(name);

      // =======================================
      // ======= FIREBASE BERHASIL =============
      // =======================================

      // Menampilkan pesan berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Buat Akun Berhasil!")),
      );

      // Navigasi ke halaman login setelah berhasil daftar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Tangani error dari Firebase Authentication

      String errorMessage = "Terjadi kesalahan saat registrasi";

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email sudah terdaftar";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password terlalu lemah";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      // Tangani error umum lainnya
      _showErrorSnackBar("Terjadi kesalahan");
    } finally {
      // Loading dihentikan
      setState(() => _isLoading = false);
    }
  }

  // Tampilan UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9D33C),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 15),

            // Tombol kembali di pojok kiri atas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Header: Judul dan deskripsi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      "Sign in",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Masuk ke akun Anda untuk pengalaman belanja yang lebih mudah dan nyaman!",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 50),

            // Container putih untuk form
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Input nama
                    buildTextField("Masukkan Nama", Icons.person, nameController),

                    SizedBox(height: 18),

                    // Input email
                    buildTextField("Masukkan Email", Icons.email, emailController),

                    SizedBox(height: 18),

                    // Input password
                    buildTextField("Masukkan Password", Icons.lock, passwordController, obscureText: true),

                    SizedBox(height: 18),

                    // Input konfirmasi password
                    buildTextField("Konfirmasi Password", Icons.lock, confirmPasswordController, obscureText: true),

                    SizedBox(height: 40),

                    // Tombol Sign In (untuk daftar akun)
                    Container(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          minimumSize: Size(double.infinity, 50),
                          elevation: 5,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // Tautan ke halaman login jika user sudah punya akun
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            },
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Sudah punya akun? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              TextSpan(
                                text: "Login",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat TextField dengan label dan ikon
  Widget buildTextField(String label, IconData icon, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            labelText: label,
            labelStyle: TextStyle(color: Colors.black54, fontFamily: 'Inter'),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
