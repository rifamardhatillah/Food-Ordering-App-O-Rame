// lib/password_reset_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

// --- PENJELASAN WIDGET ---
// PasswordResetScreen adalah widget yang 'hidup' (StatefulWidget).
// Artinya, tampilannya bisa berubah-ubah, misalnya saat kita menekan tombol,
// ia bisa menampilkan lingkaran loading.
class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

// --- PENJELASAN STATE CLASS ---
// _PasswordResetScreenState adalah 'otak' dan 'memori' untuk halaman PasswordResetScreen.
// Semua data dan logika untuk halaman ini disimpan di sini.
class _PasswordResetScreenState extends State<PasswordResetScreen> {
  // Ini seperti 'remote control' untuk kotak input email.
  // Gunanya untuk membaca tulisan yang diketik pengguna.
  final TextEditingController _emailController = TextEditingController();

  // Ini adalah 'koneksi' atau 'pintu masuk' kita ke layanan Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ini adalah 'saklar' penanda. Jika `true`, berarti sedang sibuk (loading).
  // Jika `false`, berarti sedang tidak melakukan apa-apa.
  // Kita pakai ini untuk menampilkan/menyembunyikan loading dan menonaktifkan tombol.
  bool _isLoading = false;

  // --- PENJELASAN FUNGSI ---

  // Fungsi praktis untuk menampilkan pesan kecil yang muncul sebentar di bawah layar (SnackBar).
  void _showSnackBar(String message, {bool isError = false}) {
    // Ini penting! Kita cek dulu apakah halamannya masih ada di layar sebelum menampilkan pesan.
    // Ini mencegah error jika pengguna keburu pindah halaman lain.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Warna pesan disesuaikan: merah untuk error, hijau untuk sukses.
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating, // Pesannya dibuat sedikit 'mengambang'.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3), // Atur berapa lama pesan ditampilkan.
      ),
    );
  }

  // Ini adalah fungsi utama yang akan dijalankan saat tombol "Kirim" ditekan.
  Future<void> _sendPasswordResetEmail() async {
    // 1. CEK DULU INPUT PENGGUNA (VALIDASI)
    // Ambil teks dari kotak email, dan hilangkan spasi kosong di depan/belakang.
    final email = _emailController.text.trim();
    // Periksa apakah kotaknya kosong atau format emailnya salah (tidak ada '@').
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Tolong masukkan alamat email yang benar.", isError: true);
      return; // Hentikan proses jika email tidak valid.
    }

    // 2. UBAH TAMPILAN KE MODE LOADING
    if (!mounted) return; // Cek keamanan lagi.
    setState(() {
      _isLoading = true; // 'Nyalakan' saklar loading, nanti UI akan otomatis berubah.
    });

    // 3. COBA KIRIM EMAIL LEWAT FIREBASE
    // Ini adalah blok 'coba-kalau-gagal'. Kita akan mencoba melakukan sesuatu yang berisiko (seperti koneksi ke internet).
    try {
      // Kita minta Firebase untuk mengirim email reset password ke alamat yang dimasukkan.
      // Kata `await` artinya aplikasi kita akan 'sabar menunggu' sampai proses ini selesai.
      await _auth.sendPasswordResetEmail(email: email);
      
      // 4. JIKA PROSES PENGIRIMAN SUKSES
      _showSnackBar("Link reset password sudah dikirim ke email kamu. Cek inbox ya!");

      // Kita kasih jeda 3 detik biar pengguna sempat baca pesan suksesnya.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          // Setelah jeda, kita 'tutup' halaman ini dan kembali ke halaman sebelumnya (biasanya halaman Login).
          Navigator.of(context).pop();
        }
      });
      
    } on FirebaseAuthException catch (e) {
      // 5. JIKA GAGAL, TAPI DARI FIREBASE (ERROR SPESIFIK)
      // Blok ini akan jalan kalau Firebase yang bilang 'gagal'.
      String pesanError = "Gagal mengirim email. Coba lagi nanti.";
      
      // Kita terjemahkan kode error dari Firebase menjadi pesan yang mudah dimengerti.
      if (e.code == 'user-not-found') {
        pesanError = "Email ini belum terdaftar di aplikasi kami.";
      } else if (e.code == 'invalid-email'){
        pesanError = "Format email yang kamu masukkan salah.";
      }
      _showSnackBar(pesanError, isError: true);
      
    } catch (e) {
      // 6. JIKA GAGAL KARENA MASALAH LAIN (ERROR UMUM)
      // Blok ini untuk menangkap semua jenis error lain, misalnya HP tidak ada koneksi internet.
      _showSnackBar("Terjadi kesalahan. Periksa koneksi internetmu.", isError: true);
      
    } finally {
      // 7. APAPUN HASILNYA (SUKSES/GAGAL), LAKUKAN INI
      // Blok `finally` akan selalu dijalankan.
      // Kita hanya perlu mematikan loading jika terjadi error.
      // Kenapa? Karena kalau sukses, halamannya sudah keburu ditutup (`pop`), jadi tidak perlu mematikan loading lagi.
      if (mounted && _isLoading) { 
        setState(() {
          _isLoading = false; // 'Matikan' saklar loading agar tombol bisa ditekan lagi.
        });
      }
    }
  }


  // --- PENJELASAN TAMPILAN (UI) ---
  @override
  Widget build(BuildContext context) {
    // `Scaffold` adalah kerangka dasar dari sebuah halaman (seperti kanvas).
    return Scaffold(
      backgroundColor: Color(0xFFF9D33C), // Warna latar belakang halaman.
      // `AppBar` adalah bilah judul di bagian atas.
      appBar: AppBar( 
        backgroundColor: Colors.white,
        elevation: 0, // Hapus bayangan di bawah AppBar.
        leading: IconButton( // Tombol di paling kiri AppBar (biasanya untuk kembali).
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Fungsi untuk kembali.
        ),
        title: Text(
          "Reset Password",
          style: TextStyle(color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Posisikan judul di tengah.
      ),
      // `SingleChildScrollView` membuat konten di dalamnya bisa di-scroll jika tidak muat di layar.
      body: SingleChildScrollView( 
        child: Column(
          children: [
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teks judul dan deskripsi.
                    Text(
                      "Lupa Password Anda?",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Tenang saja! Masukkan email akunmu dan kami akan kirim link untuk reset password.",
                      style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7), fontFamily: 'Inter', height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                children: [
                  // Kita panggil 'cetakan' untuk membuat kotak input email.
                  _buildEmailTextField("Alamat Email", Icons.email_outlined, _emailController),
                  SizedBox(height: 30),
                  // Tombol untuk mengirim email.
                  ElevatedButton(
                    // Logika tombol: Jika sedang loading, tombol tidak bisa ditekan (nonaktif).
                    // Jika tidak, tombol bisa ditekan dan akan menjalankan fungsi `_sendPasswordResetEmail`.
                    onPressed: _isLoading ? null : _sendPasswordResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      minimumSize: Size(double.infinity, 55), // Buat tombol jadi lebar penuh.
                    ),
                    // Tampilan tombol juga bisa berubah sesuai kondisi.
                    child: _isLoading
                        ? SizedBox( // Jika loading, tampilkan ikon lingkaran berputar.
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text( // Jika tidak loading, tampilkan teks biasa.
                            "Kirim Link Reset",
                            style: TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ini adalah 'cetakan' atau fungsi pembantu untuk membuat kotak input.
  // Tujuannya agar kode di dalam `build` jadi lebih rapi dan tidak mengulang kode yang sama.
  Widget _buildEmailTextField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress, // Tampilkan keyboard yang cocok untuk email.
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54, size: 20),
            hintText: "Contoh: email@gmail.com",
            hintStyle: TextStyle(color: Colors.black45, fontFamily: 'Inter', fontSize: 14),
            filled: true,
            fillColor: Colors.grey[200], // Warna isi kotak input.
            // Atur agar sudutnya melengkung dan tidak ada garis batas.
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
             enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            // Beri garis batas saat kotak input sedang diketik (fokus).
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFF9D33C).withOpacity(0.8), width: 1.5),
            ),
          ),
          style: TextStyle(fontFamily: 'Inter', fontSize: 15),
        ),
      ],
    );
  }
}