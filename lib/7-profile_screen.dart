import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- PENJELASAN IMPORTS ---
// 'material.dart': Paket dasar dari Flutter untuk membangun UI dengan Material Design (widget seperti Scaffold, Text, dll.).
// 'firebase_auth.dart': Paket dari Firebase untuk menangani otentikasi pengguna (login, logout, registrasi, info user).
// 'cloud_firestore.dart': Paket dari Firebase untuk berinteraksi dengan database Firestore (membaca dan menulis data).
import 'firebase_service.dart'; // Import file lokal yang kemungkinan berisi logika terpusat untuk interaksi Firebase.
import '2-welcome_screen.dart'; // Import layar Selamat Datang, untuk navigasi saat logout.
import '5-home_screen.dart'; // Import layar Home, untuk navigasi dari bottom bar.
import '6-checkout.dart'; // Import layar Checkout, untuk navigasi dari bottom bar.
import '8-tim.dart'; // Import layar Tim, untuk navigasi dari bottom bar.

// --- PENJELASAN WIDGET ---
// ProfileScreen adalah StatefulWidget. Artinya, widget ini memiliki 'state' (data) yang bisa berubah selama widget aktif,
// dan UI-nya bisa diperbarui secara otomatis ketika state tersebut berubah (menggunakan setState).
class ProfileScreen extends StatefulWidget {
  // --- PENJELASAN PARAMETER CONSTRUCTOR ---
  // Parameter ini digunakan untuk menerima data dari layar sebelumnya (misalnya, dari CheckoutScreen setelah order berhasil).
  // Mereka bersifat opsional (nullable, ditandai dengan '?').

  // initialCart: Menyimpan data keranjang belanja saat ini. Berguna agar tidak perlu fetch ulang dari Firestore jika data sudah ada.
  final List<Map<String, dynamic>>? initialCart;
  // newlyCreatedOrderId: ID dari order yang baru saja dibuat.
  final String? newlyCreatedOrderId;
  // newlyCreatedOrderTotal: Total harga dari order yang baru saja dibuat.
  final int? newlyCreatedOrderTotal;
  // newlyCreatedOrderItems: Daftar item dari order yang baru saja dibuat.
  final List<Map<String, dynamic>>? newlyCreatedOrderItems;

  const ProfileScreen({
    Key? key,
    this.initialCart,
    this.newlyCreatedOrderId,
    this.newlyCreatedOrderTotal,
    this.newlyCreatedOrderItems,
  }) : super(key: key);

  @override
  // Membuat instance dari State class yang akan mengelola data dan logika untuk widget ini.
  _ProfileScreenState createState() => _ProfileScreenState();
}

// --- PENJELASAN STATE CLASS ---
// _ProfileScreenState adalah class yang menampung semua state dan logika untuk ProfileScreen.
class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE DAN VARIABEL ---

  // Instance dari service Firebase untuk mempermudah akses fungsi-fungsi Firebase.
  final FirebaseService _firebaseService = FirebaseService();
  // Instance langsung ke Cloud Firestore untuk query data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Variabel untuk menyimpan data user yang sedang login dari Firebase Auth.
  User? _currentUser;
  // Variabel untuk menyimpan data user dari koleksi 'users' di Firestore (nama, alamat, dll).
  Map<String, dynamic>? _userDataFromFirestore;

  // State untuk menampilkan nama dan email di UI. Diinisialisasi dengan 'Loading...'
  String _displayName = 'Loading...';
  String _displayEmail = 'Loading...';

  // State untuk menyimpan riwayat pesanan yang diambil dari Firestore.
  List<Map<String, dynamic>> _orderHistoryFromFirestore = [];
  // State boolean untuk menandakan apakah proses pengambilan data riwayat pesanan sedang berlangsung.
  bool _isLoadingOrders = true;

  // State untuk mengelola paginasi (halaman) pada daftar riwayat pesanan.
  int _currentPage = 0;
  final int _itemsPerPage = 3; // Menentukan jumlah item yang ditampilkan per halaman.

  // State untuk menyimpan data keranjang belanja saat ini.
  List<Map<String, dynamic>> _currentCart = [];

  // Konstanta warna untuk digunakan di seluruh UI widget ini agar konsisten.
  final Color yellowColor = const Color(0xFFFFD428);

  // --- LIFECYCLE METHOD: initState ---
  // Metode ini dipanggil sekali saat State object pertama kali dibuat.
  // Ini adalah tempat yang ideal untuk melakukan inisialisasi data.
  @override
  void initState() {
    super.initState();
    // Memulai proses memuat semua data yang diperlukan oleh layar ini.
    _loadInitialData();
  }

  // --- FUNGSI-FUNGSI LOGIKA ---

  // Fungsi untuk mengorkestrasi pemuatan data awal secara berurutan.
  Future<void> _loadInitialData() async {
    // 1. Muat data pengguna (info dari Auth dan Firestore).
    await _loadUserData();
    // 2. Ambil riwayat pesanan dari Firestore.
    await _fetchOrderHistory();
    // 3. Ambil data keranjang belanja.
    await _fetchCart();

    // Cek jika ada data order baru yang dikirim dari layar sebelumnya.
    if (widget.newlyCreatedOrderId != null && mounted) {
      // 'mounted' adalah properti yang memastikan widget masih ada di tree sebelum memanipulasi context.
      // `WidgetsBinding.instance.addPostFrameCallback` menjadwalkan callback untuk dijalankan setelah frame pertama selesai di-render.
      // Ini cara aman untuk menampilkan SnackBar atau dialog saat initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${widget.newlyCreatedOrderId!.substring(0, 8)}... berhasil dibuat! Total: Rp ${widget.newlyCreatedOrderTotal}',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  // Fungsi untuk memuat data pengguna.
  Future<void> _loadUserData() async {
    // Dapatkan pengguna yang sedang login dari service Firebase.
    _currentUser = _firebaseService.currentUser;
    if (_currentUser != null) {
      // Jika ada pengguna yang login, ambil data lengkapnya dari koleksi 'users' di Firestore.
      _userDataFromFirestore = await _firebaseService.getUserData(
        _currentUser!.uid,
      );
      // Cek lagi 'mounted' karena proses await bisa memakan waktu, dan user bisa saja sudah meninggalkan layar ini.
      if (mounted) {
        // Panggil setState untuk memberitahu Flutter agar me-render ulang UI dengan data baru.
        setState(() {
          // Tetapkan nama tampilan. Prioritas: nama dari Firestore > nama dari profil Firebase Auth > bagian pertama dari email > 'User'.
          _displayName = _userDataFromFirestore?['name'] ??
              _currentUser?.displayName ??
              _currentUser?.email?.split('@').first ??
              'User';
          // Tetapkan email tampilan.
          _displayEmail = _currentUser?.email ?? 'Tidak ada email';
        });
      }
    } else {
      // Jika tidak ada pengguna yang login, pindahkan user ke layar Welcome.
      if (mounted) {
        // `pushAndRemoveUntil` akan membuka layar baru dan menghapus semua layar sebelumnya dari tumpukan navigasi,
        // sehingga pengguna tidak bisa menekan tombol kembali ke layar profil.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  // Fungsi untuk mengambil riwayat pesanan dari Firestore.
  Future<void> _fetchOrderHistory() async {
    // Jika tidak ada user, hentikan fungsi.
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingOrders = false);
      return;
    }
    if (!mounted) return;
    // Set state loading menjadi true untuk menampilkan indikator loading di UI.
    setState(() => _isLoadingOrders = true);
    try {
      // Lakukan query ke Firestore:
      // - Buka koleksi 'users'
      // - Pilih dokumen dengan ID pengguna saat ini
      // - Buka sub-koleksi 'orders' di dalam dokumen pengguna tersebut
      // - Urutkan hasilnya berdasarkan field 'orderDate' secara menurun (terbaru dulu)
      QuerySnapshot orderSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();
      // Ubah hasil QuerySnapshot (daftar dokumen) menjadi List<Map<String, dynamic>>.
      _orderHistoryFromFirestore = orderSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Tambahkan ID dokumen ke dalam map agar mudah diakses.
        return {'orderId': doc.id, ...data};
      }).toList();
    } catch (e) {
      // Tangani error jika gagal mengambil data.
      print("Error fetching order history: $e");
    } finally {
      // Blok 'finally' akan selalu dieksekusi, baik query berhasil maupun gagal.
      // Pastikan state loading diatur kembali ke false.
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  // Fungsi untuk mengambil data keranjang belanja dari Firestore.
  Future<void> _fetchCart() async {
    if (_currentUser == null) return;
    // Optimasi: Jika data keranjang sudah diberikan melalui constructor, gunakan data itu.
    if (widget.initialCart != null) {
      if (mounted) setState(() => _currentCart = List.from(widget.initialCart!));
      return;
    }
    // Jika tidak ada data dari constructor, ambil dari Firestore.
    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cart')
          .get();
      // Ubah hasil query menjadi List<Map>.
      _currentCart = cartSnapshot.docs.map((doc) {
        return {'cartDocId': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
      if (mounted) setState(() {}); // Panggil setState untuk memastikan UI diperbarui jika diperlukan.
    } catch (e) {
      print("Error fetching cart in ProfileScreen: $e");
    }
  }

  // Fungsi untuk mendapatkan daftar pesanan sesuai halaman saat ini (untuk paginasi).
  List<Map<String, dynamic>> getPaginatedOrders() {
    // Hitung indeks awal dari item pada halaman saat ini.
    int startIndex = _currentPage * _itemsPerPage;
    // Hitung indeks akhir.
    int endIndex = startIndex + _itemsPerPage;
    // Jika daftar pesanan kosong atau indeks awal di luar jangkauan, kembalikan list kosong.
    if (_orderHistoryFromFirestore.isEmpty ||
        startIndex >= _orderHistoryFromFirestore.length) return [];
    // Kembalikan sub-list dari daftar pesanan utama.
    return _orderHistoryFromFirestore.sublist(
      startIndex,
      // Pastikan endIndex tidak melebihi panjang list.
      endIndex > _orderHistoryFromFirestore.length
          ? _orderHistoryFromFirestore.length
          : endIndex,
    );
  }

  // Fungsi untuk menangani proses logout.
  Future<void> _handleLogout() async {
    // Panggil metode signOut dari Firebase service.
    await _firebaseService.signOut();
    if (mounted) {
      // Navigasi kembali ke WelcomeScreen dan hapus semua rute sebelumnya.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- UI METHOD: build ---
  // Metode ini dipanggil setiap kali Flutter perlu me-render UI.
  // Ini terjadi saat initState, setelah setState, atau saat konfigurasi widget berubah.
  @override
  Widget build(BuildContext context) {
    // Scaffold adalah kerangka dasar untuk halaman Material Design.
    return Scaffold(
      backgroundColor: Color(0xFFF9D33C), // Warna latar belakang utama halaman.
      // bottomNavigationBar: Menempatkan widget di bagian bawah layar.
      bottomNavigationBar: _buildBottomNavigationBar(
        context,
        _displayName,
        _displayEmail,
      ),
      // SingleChildScrollView: Membuat konten di dalamnya bisa di-scroll jika melebihi ukuran layar.
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Halaman
            ClipRRect(
              // Memberikan sudut melengkung hanya di bagian bawah.
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 25), // Memberi jarak dari atas.
                    Row(
                      children: [
                        // ========== Tombol Kembali (Back Button) ==========
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            // Logika navigasi yang cerdas:
                            // Cek apakah ada halaman sebelumnya di tumpukan navigasi.
                            if (Navigator.canPop(context)) {
                              // Jika ya, kembali ke halaman tersebut.
                              Navigator.pop(context);
                            } else {
                              // Jika tidak (misalnya, ini adalah halaman pertama yang dibuka),
                              // navigasi ke HomeScreen sebagai fallback agar aplikasi tidak macet.
                              // `pushReplacement` mengganti layar saat ini dengan yang baru.
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomeScreen(
                                    name: _displayName,
                                    email: _displayEmail,
                                    cart: _currentCart,
                                    orderHistory: _orderHistoryFromFirestore,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        // ===============================================
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Image.asset(
                        'image/logo2.png',
                        height: 80,
                        // `errorBuilder` menangani kasus jika file gambar tidak ditemukan.
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error, size: 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 70), // Jarak antara header dan kartu profil.

            // Kartu Profil Pengguna
            // Stack digunakan untuk menumpuk widget di atas satu sama lain.
            // `clipBehavior: Clip.none` memungkinkan widget anak (avatar) untuk "keluar" dari batas Stack.
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Kontainer utama kartu profil (latar belakang putih).
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  padding: EdgeInsets.only(top: 70, bottom: 30), // Padding atas lebih besar untuk memberi ruang bagi avatar.
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [ // Memberi efek bayangan agar kartu terlihat "mengambang".
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "Nama Pengguna",
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 5),
                      // Memanggil helper widget untuk menampilkan nama pengguna.
                      buildInfoField(Icons.person, _displayName),
                      SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "Email",
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 5),
                      // Memanggil helper widget untuk menampilkan email.
                      buildInfoField(Icons.email, _displayEmail),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: ElevatedButton.icon(
                          // Menghubungkan tombol dengan fungsi logout.
                          onPressed: _handleLogout,
                          icon: Icon(Icons.logout),
                          label: Text("Logout", style: TextStyle(fontFamily: 'Inter')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF9D33C),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            minimumSize: Size(double.infinity, 45), // Membuat tombol selebar kartu.
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar Pengguna (diposisikan di atas kartu).
                Positioned(
                  top: -40, // Posisi -40px dari atas Stack, membuatnya "keluar".
                  left: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white, // Lingkaran putih sebagai border.
                    child: CircleAvatar(
                      radius: 40,
                      // Logika untuk menampilkan gambar profil:
                      // Jika URL foto ada di profil Firebase Auth, gunakan NetworkImage.
                      // Jika tidak, gunakan gambar aset lokal sebagai default.
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : AssetImage('image/profile.png') as ImageProvider,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),

            // Kartu Detail Order Baru (kondisional)
            // Bagian ini hanya akan muncul jika `widget.newlyCreatedOrderId` tidak null.
            if (widget.newlyCreatedOrderId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Card(
                  color: Colors.green[50],
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail Order Baru (ID: ${widget.newlyCreatedOrderId})",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                        SizedBox(height: 8),
                        // Menampilkan daftar item dari order baru.
                        if (widget.newlyCreatedOrderItems != null)
                          // `...` (spread operator) untuk memasukkan list widget ke dalam Column.
                          ...widget.newlyCreatedOrderItems!.map(
                            (item) => Text(
                              "- ${item['productName']} (Qty: ${item['quantity'] ?? 0})",
                              style: TextStyle(fontSize: 14),
                            ),
                          ).toList(),
                        SizedBox(height: 8),
                        // Menghitung total item.
                        Text(
                          "Total Item: ${widget.newlyCreatedOrderItems?.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0)) ?? 0} pcs",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        // Menampilkan total pembayaran.
                        Text(
                          "Total Pembayaran: Rp ${widget.newlyCreatedOrderTotal ?? 0}",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Riwayat Pembelian
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Riwayat Pembelian",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter'),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                // Logika Tampilan Kondisional untuk Riwayat Pesanan
                child: _isLoadingOrders
                    ? Center( // 1. Jika sedang loading, tampilkan CircularProgressIndicator.
                        child: CircularProgressIndicator(color: Color(0xFFF9D33C)),
                      )
                    : _orderHistoryFromFirestore.isEmpty
                        ? Column( // 2. Jika loading selesai dan data kosong, tampilkan pesan.
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 20),
                              Icon(Icons.restaurant_menu_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 5),
                              Text("Kamu belum melakukan pembelian", style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
                              SizedBox(height: 20),
                            ],
                          )
                        : Column( // 3. Jika loading selesai dan ada data, tampilkan daftar pesanan.
                            children: [
                              // Menggunakan `getPaginatedOrders()` untuk hanya menampilkan item di halaman saat ini.
                              ...getPaginatedOrders().map((order) {
                                // Ekstraksi data dari map 'order' untuk ditampilkan.
                                String orderId = order['orderId'] ?? 'N/A';
                                int totalAmount = order['totalAmount'] as int? ?? 0;
                                Timestamp orderDate = order['orderDate'] as Timestamp? ?? Timestamp.now();
                                List<dynamic> itemsInOrder = order['items'] as List<dynamic>? ?? [];
                                int totalQuantityInOrder = itemsInOrder.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
                                String firstItemName = itemsInOrder.isNotEmpty ? (itemsInOrder.first['productName'] ?? "Produk tidak ada") : "Item tidak ada";
                                String firstItemImage = itemsInOrder.isNotEmpty ? (itemsInOrder.first['image'] ?? 'image/placeholder.png') : 'image/placeholder.png';

                                // Widget untuk menampilkan satu item riwayat pesanan.
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        // Cek apakah gambar dari URL atau aset lokal.
                                        child: (firstItemImage.startsWith('http'))
                                            ? Image.network(
                                                firstItemImage, width: 80, height: 80, fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image)),
                                              )
                                            : Image.asset(
                                                firstItemImage, width: 80, height: 80, fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image)),
                                              ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded( // Mengambil sisa ruang agar teks tidak overflow.
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              // Tampilkan nama item pertama dan jumlah item lainnya jika ada.
                                              itemsInOrder.length > 1 ? "$firstItemName (dan ${itemsInOrder.length - 1} lainnya)" : firstItemName,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text("Order ID: #...${orderId.substring(orderId.length - 5)}", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey[600])),
                                            Text("Tgl: ${orderDate.toDate().day}/${orderDate.toDate().month}/${orderDate.toDate().year}", style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                                            Text("Total Item: $totalQuantityInOrder pcs", style: TextStyle(fontFamily: 'Inter')),
                                            Text("Total: Rp $totalAmount", style: TextStyle(fontFamily: 'Inter', color: Colors.green[800], fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              // Kontrol Paginasi
                              // Tampilkan kontrol hanya jika jumlah halaman lebih dari 1.
                              if ((_orderHistoryFromFirestore.length / _itemsPerPage).ceil() > 1)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      // Nonaktifkan tombol jika di halaman pertama.
                                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                      icon: Icon(Icons.arrow_back_ios, size: 16),
                                    ),
                                    // Membuat tombol bernomor secara dinamis.
                                    ...List.generate(
                                      (_orderHistoryFromFirestore.length / _itemsPerPage).ceil(),
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: ElevatedButton(
                                          onPressed: () => setState(() => _currentPage = index),
                                          // Ubah gaya tombol jika itu adalah halaman saat ini.
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _currentPage == index ? Colors.black : Colors.grey[300],
                                            foregroundColor: _currentPage == index ? Colors.white : Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            minimumSize: Size(35, 35),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Text("${index + 1}"),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      // Nonaktifkan tombol jika di halaman terakhir.
                                      onPressed: (_currentPage + 1) * _itemsPerPage < _orderHistoryFromFirestore.length ? () => setState(() => _currentPage++) : null,
                                      icon: Icon(Icons.arrow_forward_ios, size: 16),
                                    ),
                                  ],
                                ),
                            ],
                          ),
              ),
            ),
            SizedBox(height: 20), // Jarak di akhir halaman.
          ],
        ),
      ),
    );
  }

  // --- WIDGET PEMBANTU (HELPER WIDGETS) ---

  // Helper widget untuk membuat field info yang tidak bisa diedit.
  // Ini membantu menghindari duplikasi kode dan membuat `build` method lebih rapi.
  Widget buildInfoField(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextField(
        enabled: false, // Membuat field tidak bisa di-tap atau diedit.
        readOnly: true,
        // Menggunakan TextEditingController untuk menampilkan teks.
        controller: TextEditingController(text: value),
        style: TextStyle(color: Colors.black, fontFamily: 'Inter'),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          // `disabledBorder` digunakan karena field-nya `enabled: false`.
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none, // Tanpa garis batas.
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        ),
      ),
    );
  }

  // Helper widget untuk membangun Bottom Navigation Bar.
  Widget _buildBottomNavigationBar(
    BuildContext context,
    String currentUserName,
    String currentUserEmail,
  ) {
    // BottomAppBar memberikan penempatan standar untuk item navigasi bawah.
    return BottomAppBar(
      color: Colors.transparent, // Transparan agar warna Scaffold terlihat.
      elevation: 0, // Tanpa bayangan.
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black, // Latar belakang hitam untuk bar.
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Menyebar item secara merata.
            children: [
              // Memanggil helper untuk setiap item navigasi.
              _buildNavItem(Icons.phone, "Tim", context, currentUserName, currentUserEmail, isActive: false),
              _buildNavItem(Icons.home, "Home", context, currentUserName, currentUserEmail, isActive: false),
              _buildNavItem(Icons.shopping_cart, "Keranjang", context, currentUserName, currentUserEmail, isActive: false),
              // Item 'Profil' ditandai sebagai aktif karena kita berada di halaman ini.
              _buildNavItem(Icons.person, "Profil", context, currentUserName, currentUserEmail, isActive: true),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget untuk membangun satu item di Bottom Navigation Bar.
  Widget _buildNavItem(
    IconData icon,
    String label,
    BuildContext context,
    String currentUserName,
    String currentUserEmail, {
    required bool isActive,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        // Ubah warna ikon berdasarkan status aktif atau tidak.
        color: isActive ? yellowColor : const Color(0xFFF9D33C),
        size: 24,
      ),
      tooltip: label, // Teks yang muncul saat ikon ditekan lama.
      onPressed: () async {
        if (isActive) return; // Jika sudah di halaman ini, jangan lakukan apa-apa.
        // Logika navigasi berdasarkan ikon yang ditekan.
        if (icon == Icons.person) {
          /* Tidak melakukan apa-apa karena sudah di halaman profil */
        } else if (icon == Icons.home) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                name: currentUserName,
                email: currentUserEmail,
                cart: _currentCart,
                orderHistory: _orderHistoryFromFirestore,
              ),
            ),
            (route) => false, // Hapus semua rute sebelumnya.
          );
        } else if (icon == Icons.shopping_cart) {
          // 'await' digunakan di sini untuk menunggu sampai layar Checkout ditutup.
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutScreen(
                name: currentUserName,
                email: currentUserEmail,
              ),
            ),
          );
          // Setelah kembali dari Checkout, panggil ulang fetch data untuk memperbarui
          // keranjang (jika ada perubahan) dan riwayat pesanan (jika ada order baru).
          _fetchCart();
          _fetchOrderHistory();
        } else if (icon == Icons.phone) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamPage(
                cart: _currentCart,
                name: currentUserName,
                email: currentUserEmail,
                orderHistory: _orderHistoryFromFirestore,
              ),
            ),
          );
        }
      },
    );
  }
}