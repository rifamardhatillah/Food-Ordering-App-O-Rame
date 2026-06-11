import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '7-profile_screen.dart';
import 'detail.dart';
import '6-checkout.dart';
import '8-tim.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String email;
  final List<Map<String, dynamic>> initialCart;
  final List<Map<String, dynamic>> initialOrderHistory;

  HomeScreen({
    Key? key,
    required this.name,
    required this.email,
    List<Map<String, dynamic>>? cart,
    List<Map<String, dynamic>>? orderHistory,
  })  : this.initialCart = cart ?? [],
        this.initialOrderHistory = orderHistory ?? [],
        super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- PENJELASAN INISIALISASI FIREBASE ---
  // Membuat objek untuk berinteraksi dengan Cloud Firestore (database).
  // Lewat objek '_firestore' ini kita bisa membaca dan menulis data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Membuat objek untuk berinteraksi dengan Firebase Authentication (layanan user).
  // Lewat objek '_auth' ini kita bisa mendapatkan info user yang sedang login.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variabel-variabel state untuk menyimpan data yang diambil dari Firestore
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> orderHistory = [];
  List<Map<String, dynamic>> _allProducts = [];
  String selectedCategory = "Food";
  bool _isLoadingProducts = true;
  bool _isLoadingCart = true;

  final Color yellowColor = const Color(0xFFFFD428);

  String _extractVideoId(dynamic ytbField) {
    if (ytbField == null) return '';
    final url = ytbField.toString();
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    }
    return '';
  }

  // --- PENJELASAN PROSES MENGAMBIL DATA PRODUK DARI FIRESTORE ---
  Future<void> _fetchProductsFromFirestore() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });
    try {
      // 1. Mengambil semua dokumen dari koleksi (collection) bernama 'products' di Firestore.
      // `await` digunakan karena proses ini butuh waktu (menunggu response dari server).
      QuerySnapshot querySnapshot =
          await _firestore.collection('products').get();
      
      // 2. Mengubah setiap dokumen yang didapat dari Firestore menjadi format Map (kamus data) yang mudah digunakan di Flutter.
      final List<Map<String, dynamic>> fetchedProducts =
          querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id, // Menyimpan ID unik dari dokumen produk, ini sangat penting!
          'name': data['name'] ?? 'No Name',
          'price': (data['price'] ?? 0).toInt(),
          'image': data['image'] ?? '',
          'category': data['category'] ?? 'Uncategorized',
          'description': data['description'] ?? 'No description available.',
          'ytb': data['ytb'],
          'youtubeVideoId': _extractVideoId(data['ytb']),
        };
      }).toList();

      // 3. Setelah data berhasil didapat dan diolah, update state untuk menampilkannya di UI.
      if (mounted) {
        setState(() {
          _allProducts = fetchedProducts;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      // Menangani jika terjadi error saat mengambil data (misal: tidak ada internet).
      print("Error fetching products: $e");
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat produk: ${e.toString()}")));
      }
    }
  }

  // --- PENJELASAN PROSES MENGAMBIL DATA KERANJANG (CART) SPESIFIK USER DARI FIRESTORE ---
  Future<void> _fetchCartFromFirestore() async {
    // 1. Mendapatkan informasi user yang sedang login saat ini.
    User? user = _auth.currentUser;
    // Jika tidak ada user yang login, proses berhenti.
    if (user == null) {
      if (mounted) setState(() => _isLoadingCart = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoadingCart = true);

    try {
      // 2. Mengambil data dari sub-collection 'cart' yang ada di dalam dokumen user yang sedang login.
      // Strukturnya: collection('users') -> doc(ID_USER_LOGIN) -> collection('cart')
      // Ini memastikan setiap user hanya melihat keranjangnya sendiri.
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid) // user.uid adalah ID unik user dari Firebase Auth.
          .collection('cart')
          .orderBy('addedDate', descending: true) // Mengurutkan data
          .get();

      // 3. Mengubah data dari Firestore menjadi List<Map> untuk digunakan di aplikasi.
      final List<Map<String, dynamic>> fetchedCart =
          cartSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'cartDocId': doc.id, // Menyimpan ID dokumen dari item di keranjang, penting untuk update/delete nanti.
        };
      }).toList();

      // 4. Update state 'cart' dengan data yang baru diambil.
      if (mounted) {
        setState(() {
          cart = fetchedCart;
          _isLoadingCart = false;
        });
      }
    } catch (e) {
      print("Error fetching cart: $e");
      if (mounted) {
        setState(() => _isLoadingCart = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat keranjang: ${e.toString()}")));
      }
    }
  }

  // --- PENJELASAN PROSES MENGAMBIL RIWAYAT ORDER USER DARI FIRESTORE ---
  Future<void> _fetchOrderHistoryFromFirestore() async {
    // Proses ini sangat mirip dengan mengambil keranjang, tapi targetnya adalah sub-collection 'orders'.
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Mengambil data dari: collection('users') -> doc(ID_USER_LOGIN) -> collection('orders')
      QuerySnapshot historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();

      final List<Map<String, dynamic>> fetchedHistory =
          historySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'orderId': doc.id,
        };
      }).toList();

      if (mounted) {
        setState(() {
          orderHistory = fetchedHistory;
        });
      }
    } catch (e) {
      print("Error fetching order history: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    cart = List<Map<String, dynamic>>.from(widget.initialCart);
    orderHistory = List<Map<String, dynamic>>.from(widget.initialOrderHistory);
    
    // Saat halaman pertama kali dibuka, panggil fungsi untuk mengambil semua data dari Firebase.
    _fetchProductsFromFirestore();
    if (_auth.currentUser != null) {
      _fetchCartFromFirestore();
      _fetchOrderHistoryFromFirestore();
    } else {
      _isLoadingCart = false;
    }

    // --- PENJELASAN LISTENER STATUS AUTENTIKASI ---
    // Ini adalah listener yang akan "mendengarkan" perubahan status login user.
    // Jika user login, blok kode di dalamnya akan dijalankan.
    // Jika user logout, blok kode di dalamnya juga akan dijalankan.
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Jika user baru saja login, ambil data keranjang dan riwayat ordernya.
        _fetchCartFromFirestore();
        _fetchOrderHistoryFromFirestore();
      } else {
        // Jika user baru saja logout, kosongkan data keranjang dan riwayat order di aplikasi.
        if (mounted) {
          setState(() {
            cart = [];
            orderHistory = [];
            _isLoadingCart = false;
          });
        }
      }
    });
  }

  // --- PENJELASAN PROSES MENAMBAH/UPDATE ITEM KE KERANJANG DI FIRESTORE ---
  Future<void> addItemToCartFromDetail(
      Map<String, dynamic> itemFromDetail) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silakan login untuk menambah ke keranjang.")));
      return;
    }

    String productId = itemFromDetail['id'] as String;
    int quantityToAdd = itemFromDetail['quantity'] as int? ?? 1;

    // 1. Cek dulu apakah produk ini sudah ada di keranjang user di Firestore.
    // Kita melakukan query ke Firestore: "Cari di dalam keranjang user ini, dokumen yang field 'id'-nya sama dengan productId".
    QuerySnapshot existingCartItemQuery = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .where('id', isEqualTo: productId) // 'where' adalah filter/kondisi pencarian.
        .limit(1) // Cukup cari 1 saja, karena seharusnya produk tidak duplikat.
        .get();

    if (existingCartItemQuery.docs.isNotEmpty) {
      // 2. JIKA PRODUK SUDAH ADA: Lakukan UPDATE kuantitas.
      DocumentSnapshot cartDoc = existingCartItemQuery.docs.first;
      int currentQuantity = cartDoc['quantity'] as int? ?? 0;
      int newQuantity = currentQuantity + quantityToAdd;
      
      // Menggunakan method 'update' untuk mengubah field 'quantity' pada dokumen yang sudah ada.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartDoc.id) // Targetkan dokumen spesifik menggunakan ID-nya.
          .update({'quantity': newQuantity});
      
      // Update juga data lokal di aplikasi agar UI langsung berubah tanpa perlu fetch ulang.
      _fetchCartFromFirestore(); // Atau fetch ulang untuk data yang paling konsisten.

    } else {
      // 3. JIKA PRODUK BELUM ADA: Lakukan ADD (tambah dokumen baru).
      Map<String, dynamic> cartItemData = {
        'id': productId, // ID produk asli
        'name': itemFromDetail['name'],
        'price': itemFromDetail['price'],
        'image': itemFromDetail['image'],
        'quantity': quantityToAdd,
        'addedDate': Timestamp.now(), // Menyimpan waktu kapan item ditambahkan.
        'userId': user.uid,
      };

      // Menggunakan method 'add' untuk membuat dokumen baru di dalam sub-collection 'cart'.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add(cartItemData);
      
      // Setelah berhasil, fetch ulang data keranjang agar item baru muncul di UI.
      _fetchCartFromFirestore();
    }
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${itemFromDetail['name']} berhasil diproses.")));
  }

  // Fungsi ini logikanya hampir sama persis dengan yang di atas,
  // bedanya ini untuk tombol tambah langsung dari kartu produk (kuantitas selalu +1).
  Future<void> addItemToCartFromProductCard(
      Map<String, dynamic> productData) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silakan login untuk menambah ke keranjang.")));
      return;
    }

    String productId = productData['id'] as String;

    // 1. Cek apakah produk sudah ada di keranjang.
    QuerySnapshot existingCartItemQuery = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .where('id', isEqualTo: productId)
        .limit(1)
        .get();

    if (existingCartItemQuery.docs.isNotEmpty) {
      // 2. JIKA ADA: Update kuantitasnya (+1).
      DocumentSnapshot cartDoc = existingCartItemQuery.docs.first;
      int currentQuantity = cartDoc['quantity'] as int? ?? 0;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartDoc.id)
          .update({'quantity': currentQuantity + 1});
      _fetchCartFromFirestore();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${productData['name']} kuantitas diupdate.")));
    } else {
      // 3. JIKA TIDAK ADA: Tambah sebagai item baru dengan kuantitas 1.
      Map<String, dynamic> cartItemData = {
        'id': productId,
        'name': productData['name'],
        'price': productData['price'],
        'image': productData['image'],
        'quantity': 1,
        'addedDate': Timestamp.now(),
        'userId': user.uid,
      };
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add(cartItemData);
      _fetchCartFromFirestore();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${productData['name']} ditambahkan ke keranjang.")));
    }
  }

  // --- Sisa kode di bawah ini mayoritas adalah tentang membangun UI (Widget), ---
  // --- dan tidak lagi berinteraksi langsung dengan Firebase. ---
  // --- Mereka menggunakan data yang sudah diambil oleh fungsi-fungsi di atas (seperti _allProducts dan cart). ---

  void changeCategory(String category) {
    if (mounted) {
      setState(() {
        selectedCategory = category;
      });
    }
  }

  void _showYouTubePlayerDialog(BuildContext context, String videoId) {
    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video review tidak tersedia.")));
      return;
    }
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.amber,
            progressColors: ProgressBarColors(
              playedColor: Colors.amber,
              handleColor: Colors.amberAccent,
            ),
          ),
          builder: (playerContext, player) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: AspectRatio(aspectRatio: 16 / 9, child: player),
              actions: <Widget>[
                TextButton(
                  child: Text('Tutup'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildCategorySection(),
          SizedBox(height: 10),
          Expanded(child: _buildProductGrid(context)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, widget.name, widget.email),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Color(0xFFF9D33C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      'image/banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Image.asset(
                    'image/logo.png',
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("KATEGORI"),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryButton("Food"),
              _buildCategoryButton("Cake"),
              _buildCategoryButton("Drink"),
            ],
          ),
          SizedBox(height: 10),
          _buildSectionTitle("PRODUK"),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    bool isSelected = selectedCategory == category;
    String emoji = category == "Food" ? "🍽" : category == "Cake" ? "🧁" : "🥤";
    return GestureDetector(
      onTap: () => changeCategory(category),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF9D33C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Text(
          "$emoji $category",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    if (_isLoadingProducts || _isLoadingCart) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFF9D33C)));
    }
    if (_allProducts.isEmpty) {
      return Center(child: Text("Tidak ada produk tersedia saat ini."));
    }

    List<Map<String, dynamic>> currentProducts = _allProducts
        .where((product) => product['category'] == selectedCategory)
        .toList();

    if (currentProducts.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada produk dalam kategori "$selectedCategory".',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: currentProducts.length,
      itemBuilder: (context, index) {
        final product = currentProducts[index];
        final String? productImage = product['image'];
        final String? youtubeVideoId = product['youtubeVideoId'];

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(product: product),
              ),
            );

            if (result != null && result is Map<String, dynamic>) {
              await addItemToCartFromDetail(result);
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: (productImage != null && productImage.isNotEmpty)
                        ? Image.network(
                            productImage,
                            fit: BoxFit.contain,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                  child: Icon(Icons.broken_image,
                                      size: 40, color: Colors.grey));
                            },
                          )
                        : Center(
                            child: Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    product['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Rp ${product['price']}",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (youtubeVideoId != null && youtubeVideoId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: TextButton.icon(
                      icon: Icon(Icons.play_circle_fill_outlined,
                          size: 18, color: Colors.red),
                      label: Text('Tonton Review',
                          style: TextStyle(
                              fontSize: 10, color: Colors.red.shade700)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          _showYouTubePlayerDialog(context, youtubeVideoId),
                    ),
                  ),
                SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, String currentUserName, String currentUserEmail) {
    final String? currentRouteName = ModalRoute.of(context)?.settings.name;
    bool isHomeActive = currentRouteName == '/';
    
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
              _buildNavItem(Icons.home, "Home", context, currentUserName, currentUserEmail, isActive: isHomeActive),
              _buildNavItem(Icons.shopping_cart, "Keranjang", context, currentUserName, currentUserEmail, isActive: false),
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
          // Saat kembali dari halaman Profile, panggil lagi fungsi fetch
          // untuk me-refresh data jika ada perubahan (misal setelah logout).
          _fetchCartFromFirestore(); 
          _fetchOrderHistoryFromFirestore();

        } else if (icon == Icons.home) {
           Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  settings: RouteSettings(name: '/'),
                  builder: (_) => HomeScreen(
                    name: currentUserName,
                    email: currentUserEmail,
                    cart: cart,
                    orderHistory: orderHistory,
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
           // Saat kembali dari halaman Checkout, panggil lagi fungsi fetch
           // untuk me-refresh data (misal setelah checkout, keranjang jadi kosong).
           _fetchCartFromFirestore();
           _fetchOrderHistoryFromFirestore();

        } else if (icon == Icons.phone) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/team_page'),
              builder: (_) => TeamPage(
                cart: cart,
                name: currentUserName,
                email: currentUserEmail,
                orderHistory: orderHistory,
              ),
            ),
          );
        }
      },
    );
  }
}