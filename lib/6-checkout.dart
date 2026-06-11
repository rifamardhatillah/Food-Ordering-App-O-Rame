import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '7-profile_screen.dart';
import '5-home_screen.dart';
import '9-order_form.dart'; // Halaman Form Order Anda
import '8-tim.dart';

class CheckoutScreen extends StatefulWidget {
  final String name;
  final String email;

  CheckoutScreen({
    Key? key,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- PENJELASAN INISIALISASI FIREBASE ---
  // Membuat objek untuk berinteraksi dengan Cloud Firestore (database).
  // Melalui objek '_firestore' ini kita bisa membaca dan menulis data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Membuat objek untuk berinteraksi dengan Firebase Authentication.
  // Di sini digunakan untuk mendapatkan ID user yang sedang login (user.uid).
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> cartItems = [];
  List<bool> checkedItems = [];
  bool _isLoading = true;
  bool _isProcessingOrder = false;
  
  final Color yellowColor = const Color(0xFFFFD428);

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi untuk mengambil data dari Firestore saat halaman pertama kali dimuat.
    _fetchCartAndHistory();
  }

  // --- PENJELASAN PROSES MENGAMBIL DATA KERANJANG (CART) DARI FIRESTORE ---
  Future<void> _fetchCartAndHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. Mendapatkan informasi user yang sedang login saat ini.
    User? user = _auth.currentUser;
    if (user == null) {
      // Jika tidak ada user yang login, hentikan proses dan tampilkan pesan.
      // Operasi Firestore pada data user memerlukan user yang sudah login.
      if (mounted) setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Silakan login untuk melihat keranjang.")));
      }
      return;
    }

    try {
      // 2. Mengakses dan mengambil data dari sub-collection 'cart' milik user yang sedang login.
      // Strukturnya: collection('users') -> doc(ID_USER_LOGIN) -> collection('cart')
      // 'user.uid' adalah ID unik dari user yang disediakan oleh Firebase Auth.
      // Ini memastikan setiap user hanya bisa melihat dan mengelola keranjangnya sendiri.
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .orderBy('addedDate', descending: true) // Mengurutkan item terbaru di atas.
          .get(); // `get()` adalah perintah untuk mengambil semua dokumen di path tersebut.

      // 3. Mengubah setiap dokumen yang didapat dari Firestore menjadi format Map (kamus data)
      //    yang bisa digunakan oleh aplikasi Flutter.
      final List<Map<String, dynamic>> fetchedCart =
          cartSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'cartDocId': doc.id, // Menyimpan ID unik dari dokumen item di keranjang. Ini SANGAT PENTING untuk proses hapus/update nanti.
          'id': data['id'], // ID produk aslinya
        };
      }).toList();

      // 4. Setelah data berhasil diambil, update state aplikasi untuk menampilkan item di UI.
      if (mounted) {
        setState(() {
          cartItems = fetchedCart;
          checkedItems = List.generate(cartItems.length, (_) => true); // Default semua item tercentang.
          _isLoading = false;
        });
      }
    } catch (e) {
      // Menangani jika terjadi error saat proses pengambilan data (misal: tidak ada koneksi internet).
      print("Error fetching data for CheckoutScreen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat data: ${e.toString()}")));
      }
    }
  }

  // --- PENJELASAN PROSES MENGHAPUS ITEM DARI KERANJANG DI FIRESTORE ---
  Future<void> _deleteItemFromCart(int index) async {
    User? user = _auth.currentUser;
    if (user == null) return; // Harus ada user yang login.
    if (index < 0 || index >= cartItems.length) return;

    final itemToDelete = cartItems[index];
    // Mengambil ID dokumen dari item yang akan dihapus. ID ini didapat saat fetch data.
    final String cartDocId = itemToDelete['cartDocId'] as String;
    final String itemNameToDelete = itemToDelete['name'] ?? 'Item';

    // Optimistic UI update: Hapus item dari UI terlebih dahulu agar responsif.
    if (mounted) {
      setState(() {
        cartItems.removeAt(index);
        checkedItems.removeAt(index);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$itemNameToDelete dihapus dari keranjang.")),
    );

    try {
      // 1. MEMANGGIL FIREBASE UNTUK MENGHAPUS DOKUMEN:
      //    Kita menargetkan dokumen spesifik di dalam sub-collection 'cart' milik user
      //    menggunakan `cartDocId` yang sudah kita simpan sebelumnya.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartDocId) // Menargetkan dokumen yang akan dihapus.
          .delete(); // `delete()` adalah perintah untuk menghapus dokumen tersebut dari Firestore.
    } catch (e) {
      // 2. JIKA PROSES HAPUS DI SERVER GAGAL:
      //    Tampilkan pesan error dan panggil ulang `_fetchCartAndHistory()` untuk
      //    menyinkronkan kembali data di aplikasi dengan data yang sebenarnya ada di server.
      print("Error deleting item from Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Gagal menghapus $itemNameToDelete dari server. Muat ulang keranjang.")),
      );
      _fetchCartAndHistory(); // Sinkronkan ulang data.
    }
  }

  int getTotal() {
    int total = 0;
    for (int i = 0; i < cartItems.length; i++) {
      if (i < checkedItems.length && checkedItems[i]) {
        final price = cartItems[i]['price'] as int? ?? 0;
        final quantity = cartItems[i]['quantity'] as int? ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  // --- PROSES LANJUT KE ORDER (TIDAK ADA INTERAKSI FIREBASE LANGSUNG DI FUNGSI INI) ---
  // Fungsi ini hanya mengumpulkan item yang dipilih dan meneruskannya ke halaman OrderPage.
  // Proses order (menyimpan order ke Firestore dan menghapus item dari keranjang)
  // akan terjadi di dalam `OrderPage`.
  Future<void> _proceedToOrderForm() async {
    List<Map<String, dynamic>> selectedItemsToOrder = [];
    for (int i = 0; i < cartItems.length; i++) {
      if (i < checkedItems.length && checkedItems[i]) {
        selectedItemsToOrder.add(cartItems[i]);
      }
    }

    if (selectedItemsToOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pilih setidaknya satu item untuk dipesan.")),
      );
      return;
    }

    if (mounted) setState(() => _isProcessingOrder = true);

    // Navigasi ke halaman Order dengan membawa data item yang dipilih.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPage(
          selectedCart: selectedItemsToOrder,
          name: widget.name,
          email: widget.email,
        ),
      ),
    );

    if (mounted) setState(() => _isProcessingOrder = false);
    // Setelah kembali dari halaman order, panggil lagi _fetchCartAndHistory().
    // Ini penting karena item yang sudah di-order seharusnya sudah dihapus dari keranjang.
    // Memanggil fungsi ini akan me-refresh tampilan keranjang.
    await _fetchCartAndHistory();
  }

  void _showConfirmationDialog() {
    List<Map<String, dynamic>> selectedItemsToOrder = [];
    for (int i = 0; i < cartItems.length; i++) {
      if (i < checkedItems.length && checkedItems[i]) {
        selectedItemsToOrder.add(cartItems[i]);
      }
    }

    if (selectedItemsToOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pilih setidaknya satu item untuk dipesan.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !_isProcessingOrder,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Anda akan melanjutkan ke form pengisian alamat dan pembayaran.\nLanjutkan?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFF9D33C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF9D33C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _proceedToOrderForm();
                    },
                    child:
                        Text('Ya, Lanjutkan', style: TextStyle(color: Colors.black)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    onPressed: () {
                      if (!_isProcessingOrder) Navigator.pop(dialogContext);
                    },
                    child: Text('Batal', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Sisa kode di bawah ini adalah untuk membangun UI dan Navigasi ---
  // Mereka tidak berinteraksi langsung dengan Firebase, tetapi menggunakan data
  // yang telah diambil oleh fungsi-fungsi di atas (seperti `cartItems`).

  Widget _buildBottomNavigationBar(BuildContext context, String currentUserName, String currentUserEmail) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.phone, "Tim", context, currentUserName, currentUserEmail, isActive: false),
              _buildNavItem(Icons.home, "Home", context, currentUserName, currentUserEmail, isActive: false),
              _buildNavItem(Icons.shopping_cart, "Keranjang", context, currentUserName, currentUserEmail, isActive: true),
              _buildNavItem(Icons.person, "Profil", context, currentUserName, currentUserEmail, isActive: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, BuildContext context, String currentUserName, String currentUserEmail, {required bool isActive}) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? yellowColor : const Color(0xFFF9D33C),
        size: 24,
      ),
      tooltip: label,
      onPressed: () async {
        if (isActive) return;

        if (icon == Icons.person) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/profile'),
              builder: (_) => ProfileScreen(),
            ),
          );
          _fetchCartAndHistory(); 

        } else if (icon == Icons.home) {
           Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  settings: RouteSettings(name: '/'),
                  builder: (_) => HomeScreen(
                    name: currentUserName,
                    email: currentUserEmail,
                    cart: cartItems,
                    orderHistory: [],
                  ),
              ),
              (route) => false,
            );

        } else if (icon == Icons.shopping_cart) {
           await Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/checkout'),
              builder: (_) => CheckoutScreen(
                name: currentUserName,
                email: currentUserEmail,
              ),
            ),
          );
           _fetchCartAndHistory();

        } else if (icon == Icons.phone) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/team_page'),
              builder: (_) => TeamPage(
                cart: cartItems,
                name: currentUserName,
                email: currentUserEmail,
                orderHistory: [],
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("CHECK OUT"),
          backgroundColor: Color(0xFFF9D33C),
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9D33C))),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                      color: Color(0xFFF9D33C),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40))),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text("CHECK OUT",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Image.asset('image/logo.png',
                            height: 40,
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.image_not_supported, size: 40)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Text("Keranjang Anda kosong.",
                          style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        if (index >= cartItems.length ||
                            index >= checkedItems.length) {
                          return SizedBox.shrink();
                        }
                        final item = cartItems[index];
                        final String? itemImageUrl = item['image'] as String?;
                        final int quantity = item['quantity'] as int? ?? 1;
                        final int price = item['price'] as int? ?? 0;

                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: checkedItems[index],
                                onChanged: (val) {
                                  if (mounted)
                                    setState(
                                        () => checkedItems[index] = val ?? false);
                                },
                                activeColor: Color(0xFFF9D33C),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (itemImageUrl != null &&
                                        itemImageUrl.isNotEmpty)
                                    ? Image.network(
                                        itemImageUrl,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (ctx, child, progress) =>
                                                progress == null
                                                    ? child
                                                    : Container(
                                                        height: 80,
                                                        width: 80,
                                                        child: Center(
                                                            child: CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                            Color>(
                                                                        Color(
                                                                            0xFFF9D33C))))),
                                        errorBuilder: (ctx, err, trace) =>
                                            Container(
                                                height: 80,
                                                width: 80,
                                                color: Colors.grey[200],
                                                child: Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 30,
                                                        color: Colors
                                                            .grey[400]))),
                                      )
                                    : Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.grey[200],
                                        child: Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 30,
                                                color: Colors.grey[400]))),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? 'No Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    SizedBox(height: 4),
                                    Text("Rp $price",
                                        style: TextStyle(
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.w600)),
                                    Text("Kuantitas : $quantity"),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteItemFromCart(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (cartItems.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, -2))
                  ],
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Dipilih:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Rp.${getTotal()}",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF9D33C))),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF9D33C),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                      onPressed: getTotal() > 0 && !_isProcessingOrder
                          ? _showConfirmationDialog
                          : null,
                      child: _isProcessingOrder
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 3))
                          : Text(
                              "Order Now (${selectedItemsCount()})",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar:
            _buildBottomNavigationBar(context, widget.name, widget.email),
      ),
    );
  }

  int selectedItemsCount() {
    return checkedItems.where((isChecked) => isChecked).length;
  }
}