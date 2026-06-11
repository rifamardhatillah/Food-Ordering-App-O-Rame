import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn;

  // Constructor untuk inisialisasi _googleSignIn
  FirebaseService()
      : _googleSignIn = GoogleSignIn(
          // clientId untuk web. Pastikan ini adalah WEB CLIENT ID yang benar dari project Anda.
          clientId: kIsWeb 
              ? '691670252295-f2d6ngoeghbj87d0sa52frec4ctb169t.apps.googleusercontent.com' 
              : null,
          scopes: ['email', 'profile'], // Scopes yang diminta dari Google
        ) {
    print("[FirebaseService] Constructor FirebaseService dipanggil dan _googleSignIn diinisialisasi.");
  }

  // Mendapatkan stream perubahan status autentikasi (berguna untuk UI reaktif)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mendapatkan user Firebase saat ini secara sinkron
  User? get currentUser => _auth.currentUser;

  // Helper untuk menyimpan atau memperbarui data pengguna di Firestore
  // Fungsi ini dipanggil setelah login/signup berhasil
  Future<void> _updateUserData(User user, {String? nameFromInput}) async {
    print("[FirebaseService] Memulai _updateUserData untuk user: ${user.uid}");
    final DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
    
    try {
      final DocumentSnapshot userDocSnapshot = await userDocRef.get();

      // Tentukan nama pengguna:
      // 1. Gunakan nameFromInput jika ada (dari form signup manual)
      // 2. Jika tidak, gunakan displayName dari objek User Firebase (biasanya dari Google)
      // 3. Jika masih null, coba ambil bagian pertama dari email
      // 4. Fallback ke 'User'
      final String userName = nameFromInput ?? user.displayName ?? user.email?.split('@').first ?? 'User';
      final String? userEmail = user.email;
      final String? userPhotoURL = user.photoURL;

      Map<String, dynamic> userDataToSave = {
        'uid': user.uid,
        'name': userName,
        'email': userEmail,
        // Hanya simpan photoURL jika ada
        if (userPhotoURL != null) 'photoURL': userPhotoURL,
      };

      if (!userDocSnapshot.exists) {
        // Pengguna baru, buat dokumen di Firestore
        print("[FirebaseService] Pengguna baru, membuat dokumen di Firestore untuk UID: ${user.uid}");
        userDataToSave['createdAt'] = FieldValue.serverTimestamp();
        // Simpan provider login (misalnya, 'google.com', 'password')
        if (user.providerData.isNotEmpty) {
          userDataToSave['provider'] = user.providerData[0].providerId;
        } else {
          userDataToSave['provider'] = 'unknown'; // Fallback jika providerData kosong
        }
        await userDocRef.set(userDataToSave);
      } else {
        // Pengguna sudah ada, update data (misalnya jika nama/foto profil dari Google berubah)
        print("[FirebaseService] Pengguna sudah ada, memperbarui dokumen di Firestore untuk UID: ${user.uid}");
        userDataToSave['updatedAt'] = FieldValue.serverTimestamp(); // Catat waktu update
        await userDocRef.update(userDataToSave);
      }
      print("[FirebaseService] _updateUserData berhasil untuk user: ${user.uid}");
    } catch (e, s) {
      print("[FirebaseService] ERROR di _updateUserData untuk user ${user.uid}: $e");
      print("[FirebaseService] StackTrace _updateUserData: $s");
      // Pertimbangkan apakah error ini kritis. Untuk sekarang, kita biarkan fungsi selesai
      // tanpa melempar ulang agar alur login utama bisa berlanjut jika memungkinkan.
    }
  }

  // Sign up dengan Email dan Password (jika Anda membutuhkannya)
  Future<User?> signUpWithEmail(String name, String email, String password) async {
    print("[FirebaseService] Memulai signUpWithEmail untuk email: $email");
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        print("[FirebaseService] User berhasil dibuat dengan email: ${user.email}, UID: ${user.uid}");
        // Update nama tampilan di Firebase Auth
        await user.updateDisplayName(name);
        // Simpan data pengguna ke Firestore, berikan 'name' dari input form
        await _updateUserData(user, nameFromInput: name); 
      }
      return user;
    } on FirebaseAuthException catch (e, s) {
      print("[FirebaseService] FirebaseAuthException saat signUpWithEmail: ${e.message} (Code: ${e.code})");
      print("[FirebaseService] Stack trace: $s");
      return null; // Kembalikan null jika gagal
    } catch (e, s) {
      print("[FirebaseService] Error umum saat signUpWithEmail: $e");
      print("[FirebaseService] Stack trace: $s");
      return null;
    }
  }

  // Sign in dengan Email dan Password (jika Anda membutuhkannya)
  Future<User?> signInWithEmail(String email, String password) async {
    print("[FirebaseService] Memulai signInWithEmail untuk email: $email");
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        print("[FirebaseService] User berhasil login dengan email: ${user.email}, UID: ${user.uid}");
        // Update data pengguna di Firestore (misalnya, untuk mencatat 'updatedAt' atau menyinkronkan info)
        await _updateUserData(user);
      }
      return user;
    } on FirebaseAuthException catch (e, s) {
      print("[FirebaseService] FirebaseAuthException saat signInWithEmail: ${e.message} (Code: ${e.code})");
      print("[FirebaseService] Stack trace: $s");
      return null;
    } catch (e, s) {
      print("[FirebaseService] Error umum saat signInWithEmail: $e");
      print("[FirebaseService] Stack trace: $s");
      return null;
    }
  }


  // Sign in dengan Google
  Future<User?> signInWithGoogle() async {
    print("[FirebaseService] Memulai signInWithGoogle...");
    try {
      print("[FirebaseService] Memulai _googleSignIn.signIn()...");
      final GoogleSignInAccount? googleUserAccount = await _googleSignIn.signIn();

      if (googleUserAccount == null) {
        print("[FirebaseService] Google sign in DIBATALKAN oleh pengguna atau GAGAL mendapatkan akun Google.");
        return null; 
      }
      print("[FirebaseService] Akun Google didapatkan: ${googleUserAccount.email}");

      print("[FirebaseService] Mendapatkan otentikasi dari akun Google...");
      final GoogleSignInAuthentication googleAuth = await googleUserAccount.authentication;
      print("[FirebaseService] Otentikasi Google didapatkan. AccessToken valid: ${googleAuth.accessToken != null}, IDToken valid: ${googleAuth.idToken != null}");

      print("[FirebaseService] Membuat AuthCredential untuk Firebase...");
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("[FirebaseService] Memanggil _auth.signInWithCredential dengan kredensial Google...");
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        print("[FirebaseService] Login Google ke Firebase BERHASIL. User UID: ${user.uid}, Email: ${user.email}");
        // Panggil _updateUserData untuk menyimpan/memperbarui info pengguna di Firestore
        await _updateUserData(user); 
        return user; // Kembalikan objek User jika berhasil
      } else {
        // Skenario ini seharusnya jarang terjadi jika signInWithCredential berhasil tanpa error
        print("[FirebaseService] User adalah null setelah signInWithCredential berhasil (tidak diharapkan).");
        return null;
      }
    } on FirebaseAuthException catch (e, s) {
      // Error spesifik dari Firebase saat mencoba sign-in dengan kredensial
      print("[FirebaseService] FirebaseAuthException saat signInWithGoogle: ${e.message} (Code: ${e.code})");
      print("[FirebaseService] Stack trace untuk FirebaseAuthException: $s");
      // Contoh: account-exists-with-different-credential, invalid-credential
      return null; // Kembalikan null jika gagal
    } catch (error, s) {
      // Error umum lainnya selama proses (misalnya, dari google_sign_in atau masalah jaringan)
      print('[FirebaseService] ERROR UMUM saat signInWithGoogle: $error');
      print("[FirebaseService] Stack trace untuk Error Umum: $s");
      return null; // Kembalikan null jika gagal
    }
  }

  // Mendapatkan data pengguna dari Firestore berdasarkan UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    print("[FirebaseService] Mencoba mendapatkan data pengguna dari Firestore untuk UID: $uid");
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        print("[FirebaseService] Data pengguna ditemukan di Firestore untuk UID: $uid");
        return snapshot.data() as Map<String, dynamic>?;
      }
      print("[FirebaseService] Data pengguna TIDAK ditemukan di Firestore untuk UID: $uid");
      return null;
    } catch (e, s) {
      print("[FirebaseService] Error saat mendapatkan data pengguna dari Firestore: $e");
      print("[FirebaseService] Stack trace: $s");
      return null;
    }
  }

  // Sign out dari Firebase dan Google
  Future<void> signOut() async {
    print("[FirebaseService] Memulai proses signOut...");
    try {
      // Selalu coba sign out dari Google, aman meskipun tidak login via Google
      await _googleSignIn.signOut();
      print("[FirebaseService] Berhasil signOut dari GoogleSignIn (jika sebelumnya login).");
      
      // Sign out dari Firebase Auth
      await _auth.signOut();
      print("[FirebaseService] Berhasil signOut dari FirebaseAuth.");
    } catch (e, s) {
      print("[FirebaseService] Error saat signOut: $e");
      print("[FirebaseService] Stack trace: $s");
      // Anda bisa memilih untuk melempar ulang error ini jika kritis
      // rethrow; 
    }
  }

  // Helper untuk mengecek status login Firebase saat ini
  bool get isLoggedIn => _auth.currentUser != null;
}