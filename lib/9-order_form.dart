import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Paket untuk menampilkan peta interaktif di Flutter.
import 'package:geocoding/geocoding.dart'; // Paket untuk mengubah koordinat (Latitude, Longitude) menjadi alamat, dan sebaliknya. Ini disebut Geocoding.
import 'package:latlong2/latlong.dart'; // Paket bantuan untuk `flutter_map` yang menyediakan objek LatLng untuk koordinat.
import '7-profile_screen.dart'; // Import halaman profil, tujuan navigasi setelah order berhasil.
import 'package:uas/custom_splash_screen.dart'; // Import splash screen kustom yang akan ditampilkan sebelum ke halaman profil.
import 'package:firebase_auth/firebase_auth.dart'; // Paket Firebase untuk otentikasi. Digunakan untuk mendapatkan info user yang sedang login.
import 'package:cloud_firestore/cloud_firestore.dart'; // Paket Firebase untuk database (Firestore). Digunakan untuk menyimpan data pesanan.

// --- PENJELASAN WIDGET ---
// OrderPage adalah StatefulWidget, artinya tampilan halaman ini bisa berubah sesuai dengan interaksi pengguna
// (misalnya saat memilih lokasi di peta, mengisi form, atau memilih metode pembayaran).
class OrderPage extends StatefulWidget {
  // --- PENJELASAN PARAMETER ---
  // Data yang diterima dari halaman sebelumnya (kemungkinan dari halaman keranjang/checkout).
  final List<Map<String, dynamic>> selectedCart; // Daftar item yang akan di-order.
  final String name; // Nama pengguna yang login, untuk diisi otomatis di form.
  final String email; // Email pengguna, untuk disimpan bersama data order.

  const OrderPage({
    Key? key,
    required this.selectedCart,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

// --- PENJELASAN STATE CLASS ---
// _OrderPageState adalah kelas yang menyimpan semua data (state) dan logika untuk OrderPage.
class _OrderPageState extends State<OrderPage> {
  // --- PENJELASAN STATE & CONTROLLER ---
  // State untuk menyimpan pilihan metode pembayaran. Awalnya null (kosong).
  String? _paymentMethod;
  // State untuk menyimpan koordinat lokasi yang dipilih di peta.
  LatLng? _selectedLocation;
  // State untuk menyimpan alamat dalam bentuk teks yang didapat dari koordinat peta.
  String? _selectedAddress;
  // Controller untuk peta, memungkinkan kita mengontrol peta (misalnya, memindahkan view).
  final MapController _mapController = MapController();
  // Controller untuk setiap TextField. Ini adalah cara untuk mendapatkan teks yang diketik pengguna.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  // State boolean untuk menandai apakah proses order sedang berjalan. Berguna untuk menampilkan loading & menonaktifkan tombol.
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    // `initState` berjalan sekali saat halaman pertama kali dibuka.
    // Di sini, kita langsung mengisi field nama dengan nama pengguna yang login.
    _nameController.text = widget.name;
  }

  @override
  void dispose() {
    // `dispose` berjalan saat halaman ditutup.
    // Penting untuk "membersihkan" controller agar tidak menyebabkan kebocoran memori (memory leak).
    _nameController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  // --- PENJELASAN FUNGSI LOGIKA ---

  // Fungsi untuk mendapatkan alamat dari koordinat GPS (Geocoding).
  Future<void> _getAddressFromLatLng(LatLng latlng) async {
    if (!mounted) return; // Cek apakah widget masih ada di tree, untuk keamanan.
    try {
      // Menggunakan paket `geocoding` untuk meminta data alamat dari server berdasarkan `latlng`.
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latlng.latitude,
        latlng.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        // setState() memberi tahu Flutter untuk membangun ulang UI dengan data baru.
        setState(() {
          // Menggabungkan bagian-bagian alamat (jalan, kelurahan, kota, dll.) menjadi satu string yang rapi.
          _selectedAddress =
              '${place.street ?? ''}${place.street != null && (place.subLocality != null || place.locality != null) ? ', ' : ''}${place.subLocality ?? ''}${place.subLocality != null && place.locality != null ? ', ' : ''}${place.locality ?? ''}${place.locality != null && place.administrativeArea != null ? ', ' : ''}${place.administrativeArea ?? ''}${place.administrativeArea != null && place.country != null ? ', ' : ''}${place.country ?? ''}'
                  .trim()
                  .replaceAll(RegExp(r'^, |,$'), '');
          // Mengisi TextField alamat secara otomatis dengan alamat yang didapat dari peta.
          _addressController.text = _selectedAddress!;
        });
      }
    } catch (e) {
      // Menangani error jika gagal, misalnya tidak ada koneksi internet.
      print('Gagal mengambil alamat dari peta: $e');
      if (mounted) {
        showMessage('Gagal mengambil alamat dari peta. Silakan isi manual.');
      }
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum memproses pesanan.
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessingOrder, // Dialog tidak bisa ditutup dengan klik di luar jika sedang proses.
      builder: (dialogContext) => Dialog(
        // ... (UI Dialog) ...
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder( // StatefulBuilder agar isi dialog bisa di-update (misal, menampilkan loading).
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pastikan semua informasi sudah benar sebelum melanjutkan!', style: TextStyle(color: Color(0xFFF9D33C), fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  // Tampilan kondisional: jika sedang proses, tampilkan loading. Jika tidak, tampilkan tombol.
                  if (_isProcessingOrder)
                    const CircularProgressIndicator(color: Color(0xFFFFC727))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          // ... (Style Tombol) ...
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC727), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () async {
                            // --- PROSES UTAMA FIREBASE DIMULAI DI SINI ---
                            
                            // 1. VALIDASI INPUT: Ambil semua data dari form dan cek apakah sudah diisi.
                            final String name = _nameController.text.trim();
                            final String contact = _contactController.text.trim();
                            final String address = _addressController.text.trim();

                            if (name.isEmpty) { showMessage("Nama penerima tidak boleh kosong!"); return; }
                            if (address.isEmpty) { showMessage("Alamat tidak boleh kosong! Pilih di peta atau isi manual."); return; }
                            if (contact.isEmpty) { showMessage("Kontak tidak boleh kosong!"); return; }
                            if (_paymentMethod == null) { showMessage("Pilih metode pembayaran terlebih dahulu!"); return; }

                            // 2. CEK STATUS LOGIN: Dapatkan user yang sedang aktif dari Firebase Auth.
                            final User? user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              showMessage("Sesi login Anda berakhir. Silakan login kembali.");
                              if (mounted) Navigator.pop(dialogContext);
                              return;
                            }

                            // 3. UBAH UI KE MODE LOADING
                            if (mounted) { setState(() { _isProcessingOrder = true; }); }
                            setDialogState(() {}); // Update UI di dalam dialog untuk menampilkan loading.

                            try {
                              // 4. PERSIAPAN DATA UNTUK FIRESTORE
                              // Mengubah list `selectedCart` menjadi format yang akan disimpan di Firestore.
                              List<Map<String, dynamic>> itemsForFirestore = widget.selectedCart.map((item) {
                                return {
                                  'productId': item['id'] ?? 'unknown_product_${DateTime.now().millisecondsSinceEpoch}',
                                  'productName': item['name'] ?? 'Unknown Product', 'price': item['price'] ?? 0,
                                  'quantity': item['quantity'] ?? 1, 'image': item['image'] ?? '',
                                };
                              }).toList();
                              
                              // Menghitung total harga pesanan.
                              int totalAmount = 0;
                              for (var item in widget.selectedCart) { totalAmount += (item['price'] as int? ?? 0) * (item['quantity'] as int? ?? 1); }
                              
                              // Membuat satu objek `Map` yang berisi semua data pesanan. Ini yang akan dikirim ke Firestore.
                              Map<String, dynamic> orderData = {
                                'userId': user.uid, 'userName': name, 'userEmail': widget.email,
                                'shippingAddress': address, 'contactNumber': contact, 'notes': _noteController.text.trim(),
                                'paymentMethod': _paymentMethod, 'items': itemsForFirestore, 'totalAmount': totalAmount,
                                'orderDate': Timestamp.now(), // Menyimpan waktu saat ini sebagai tanggal pesanan.
                                'status': 'Pending', // Status awal pesanan.
                                'location': _selectedLocation != null ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude) : null, // Simpan koordinat jika ada.
                              };

                              // 5. MENYIMPAN DATA KE FIRESTORE
                              // `await` akan menunggu proses ini selesai sebelum melanjutkan ke baris berikutnya.
                              // Ini membuat dokumen baru di dalam sub-koleksi 'orders' milik user yang sedang login.
                              DocumentReference orderRef = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders').add(orderData);

                              // 6. MENGHAPUS ITEM DARI KERANJANG (CART)
                              // Menggunakan `WriteBatch` untuk menghapus beberapa dokumen sekaligus. Ini lebih efisien.
                              WriteBatch batch = FirebaseFirestore.instance.batch();
                              bool hasItemsToRemove = false;
                              for (var orderedItem in widget.selectedCart) {
                                String? cartDocId = orderedItem['cartDocId'] as String?; // Dapatkan ID dokumen item di keranjang.
                                if (cartDocId != null && cartDocId.isNotEmpty) {
                                  // Menambahkan perintah 'delete' ke dalam batch.
                                  DocumentReference cartItemRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(cartDocId);
                                  batch.delete(cartItemRef);
                                  hasItemsToRemove = true;
                                }
                              }
                              if (hasItemsToRemove) { 
                                await batch.commit(); // Mengeksekusi semua perintah 'delete' dalam batch sekaligus.
                              }
                              
                              // 7. NAVIGASI SETELAH BERHASIL
                              // Simpan ID, total, dan item dari order yang baru dibuat untuk ditampilkan di halaman berikutnya.
                              final String createdOrderId = orderRef.id;
                              final int createdOrderTotalAmount = totalAmount;
                              final List<Map<String, dynamic>> createdOrderItemsSummary = List.from(itemsForFirestore);
                              
                              if (mounted) { Navigator.pop(dialogContext); } // Tutup dialog konfirmasi.
                              // Pindah ke halaman splash screen, yang kemudian akan otomatis mengarahkan ke halaman profil.
                              // Data order yang baru dibuat dikirim ke `ProfileScreen`.
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomSplashScreen(
                                    nextScreen: ProfileScreen(
                                      newlyCreatedOrderId: createdOrderId,
                                      newlyCreatedOrderTotal: createdOrderTotalAmount,
                                      newlyCreatedOrderItems: createdOrderItemsSummary,
                                    ),
                                  ),
                                ), (route) => false); // `(route) => false` menghapus semua halaman sebelumnya dari tumpukan.
                            } catch (e) {
                              // 8. PENANGANAN ERROR
                              print("Error processing order: $e");
                              if (mounted) { showMessage("Gagal memproses pesanan: ${e.toString()}"); }
                            } finally {
                              // 9. AKHIRI MODE LOADING
                              // Blok `finally` akan selalu dijalankan, baik proses berhasil maupun gagal.
                              if (mounted) { setState(() { _isProcessingOrder = false; }); }
                               setDialogState(() {}); // Sembunyikan loading di dialog.
                            }
                          },
                          child: const Text('Konfirmasi Pesanan'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () { if (!_isProcessingOrder) Navigator.pop(dialogContext); }, // Tombol kembali, hanya aktif jika tidak sedang proses.
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  // Fungsi utilitas untuk menampilkan pesan singkat di bagian bawah layar (SnackBar).
  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- PENJELASAN UI ---
      // Stack digunakan untuk menumpuk widget. Di sini, kita menumpuk background (kuning & hitam) di belakang konten utama.
      body: Stack(
        children: [
          // Background atas warna kuning dengan sudut melengkung.
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC727),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
            ),
          ),
          // Background bawah warna hitam dengan sudut melengkung.
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              height: 210,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(topRight: Radius.circular(80)),
              ),
            ),
          ),
          // Konten utama yang berada di atas background.
          SafeArea( // SafeArea memastikan konten tidak terhalang oleh notch atau status bar HP.
            child: Column(
              children: [
                // Header dengan tombol kembali dan judul 'Order'.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Text('Order', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // Expanded membuat SingleChildScrollView mengambil semua sisa ruang yang tersedia.
                Expanded(
                  child: SingleChildScrollView( // Membuat konten bisa di-scroll jika tidak muat di layar.
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)) ]
                      ),
                      child: Column(
                        children: [
                          // --- FORM PENGISIAN DATA ---
                          Image.asset('image/logo2.png', width: 180, height: 140, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey)),
                          const SizedBox(height: 10),
                          _buildLabel('Penerima'),
                          _buildTextField('Masukkan Nama', icon: Icons.person, controller: _nameController),
                          const SizedBox(height: 12),
                          _buildLabel('Alamat Pengiriman'),
                          _buildTextField('Masukkan Alamat Lengkap', icon: Icons.location_on, controller: _addressController, maxLines: 2),
                          const SizedBox(height: 12),
                          _buildLabel('Pilih Lokasi di Peta'),
                          const SizedBox(height: 8),
                          // Menampilkan alamat yang dipilih dari peta jika ada.
                          if (_selectedAddress != null) ...[
                            Container(
                              // ... (UI untuk menampilkan alamat terpilih) ...
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                              child: Row(children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Peta: $_selectedAddress", style: const TextStyle(fontSize: 12))),
                                IconButton(icon: const Icon(Icons.clear, size: 18, color: Colors.redAccent), onPressed: () => setState(() { _selectedAddress = null; _selectedLocation = null; }), padding: EdgeInsets.zero, constraints: const BoxConstraints())
                              ]),
                            ),
                          ],
                          // Widget Peta Interaktif.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: SizedBox(
                              height: 200,
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _selectedLocation ?? LatLng(-6.200000, 106.816666), // Lokasi awal di Jakarta.
                                  initialZoom: 13.0,
                                  onTap: (tapPosition, latlng) {
                                    // Saat peta di-tap, panggil fungsi untuk mendapatkan alamat dan update state lokasi.
                                    _getAddressFromLatLng(latlng);
                                    setState(() {
                                      _selectedLocation = latlng;
                                      if (_mapController.camera.zoom < 15) { _mapController.move(latlng, 15.0); } 
                                      else { _mapController.move(latlng, _mapController.camera.zoom); }
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'), // Layer dasar peta dari OpenStreetMap.
                                  // Menampilkan penanda (marker) di lokasi yang dipilih.
                                  if (_selectedLocation != null)
                                    MarkerLayer(markers: [
                                      Marker(point: _selectedLocation!, width: 40, height: 40, child: const Icon(Icons.location_pin, color: Colors.red, size: 40))
                                    ])
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLabel('Kontak Penerima'),
                          _buildTextField('Masukkan Nomor Telepon', icon: Icons.phone, controller: _contactController, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildLabel('Catatan (Opsional)'),
                          _buildTextField('Misal: Pagar warna hitam, dll.', icon: Icons.note, controller: _noteController, maxLines: 3),
                          const SizedBox(height: 12),
                          _buildLabel('Pembayaran'),
                          // Pilihan pembayaran menggunakan Radio button.
                          Row(
                            children: [
                              Radio<String>(
                                value: 'COD', // Nilai untuk pilihan ini.
                                groupValue: _paymentMethod, // Nilai yang saat ini terpilih.
                                onChanged: (value) => setState(() => _paymentMethod = value), // Update state saat dipilih.
                                activeColor: const Color(0xFFFFC727),
                              ),
                              const Text('COD'),
                              const SizedBox(width: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Tombol Order.
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC727), minimumSize: const Size.fromHeight(45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                            // Tombol dinonaktifkan jika `_isProcessingOrder` adalah true.
                            onPressed: _isProcessingOrder ? null : () => _showConfirmationDialog(context),
                            // Tampilan tombol juga berubah: loading atau teks.
                            child: _isProcessingOrder
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                                : const Text('Order', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET PEMBANTU (HELPER WIDGETS) ---
  // Fungsi ini dibuat agar kode di dalam `build` tidak terlalu panjang dan lebih mudah dibaca.

  // Helper untuk membuat label teks.
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Helper untuk membuat TextField dengan gaya yang konsisten.
  Widget _buildTextField(String hint,
      {IconData? icon,
      TextEditingController? controller,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}