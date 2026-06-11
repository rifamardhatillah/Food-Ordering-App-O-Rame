import 'package:flutter/material.dart';
// Pastikan import ini sesuai dengan struktur proyek Anda
import '5-home_screen.dart'; // Asumsi nama file
import '6-checkout.dart';   // Asumsi nama file
import '7-profile_screen.dart'; // Asumsi nama file

class TeamPage extends StatefulWidget {
  final String name;
  final String email;
  final List<Map<String, dynamic>> cart;
  final List<Map<String, dynamic>> orderHistory;

  TeamPage({
    super.key,
    required this.name,
    required this.email,
    required this.cart,
    required this.orderHistory,
  });

  @override
  _TeamPageState createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  // Warna utama yang digunakan di halaman
  final Color yellowColor = const Color(0xFFFFD428); // Warna kuning header dan ikon
  final Color iconInCircleColor = Colors.white; // Warna ikon di dalam lingkaran kuning

  // Icon untuk header, bisa diganti sesuai preferensi
  final IconData headerCustomerServiceIcon = Icons.headset_mic; // Contoh ikon pengganti

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Menggunakan widget.name dan widget.email untuk bottom navigation bar
      bottomNavigationBar: _buildBottomNavigationBar(context, widget.name, widget.email),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 30), // Jarak setelah header
          ContactInfoTile(
            iconData: Icons.phone,
            title: 'Telephone',
            subtitle: '+62 0825 7576 1100',
            iconBackgroundColor: yellowColor,
            iconColor: iconInCircleColor,
          ),
          ContactInfoTile(
            iconData: Icons.location_on,
            title: 'Address',
            subtitle: 'Jl. Palakali No.77,\nKukusan, Beji, Depok',
            iconBackgroundColor: yellowColor,
            iconColor: iconInCircleColor,
          ),
          ContactInfoTile(
            iconData: Icons.email,
            title: 'Gmail',
            subtitle: 'orame@gmail.com',
            iconBackgroundColor: yellowColor,
            iconColor: iconInCircleColor,
          ),
          ContactInfoTile(
            iconData: Icons.camera_alt, // Placeholder untuk Instagram
            title: 'Instagram',
            subtitle: '@orame_',
            iconBackgroundColor: yellowColor,
            iconColor: iconInCircleColor,
          ),
          const SizedBox(height: 20), // Padding di bagian bawah
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 220, // Ketinggian header disesuaikan jika perlu
          decoration: BoxDecoration(
            color: yellowColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(120),
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 45, // Sesuaikan jika menggunakan AppBar default (karena status bar)
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Konten header yang dipusatkan
        Positioned(
          top: 90, // Sesuaikan posisi vertikal
          left: 0,  // Untuk memastikan Row bisa di-center
          right: 0, // Untuk memastikan Row bisa di-center
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Memusatkan children dari Row
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Customer\nService',
                textAlign: TextAlign.center, // Memusatkan teks multi-baris
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 15), // Jarak antara teks dan ikon
              Icon(
                headerCustomerServiceIcon, // Menggunakan ikon yang baru
                size: 50,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modifikasi _buildBottomNavigationBar untuk menerima nama dan email
  Widget _buildBottomNavigationBar(BuildContext context, String currentUserName, String currentUserEmail) {
    // Mendapatkan nama route saat ini untuk menentukan item aktif
    final String? currentRouteName = ModalRoute.of(context)?.settings.name;
    IconData activeIcon = Icons.phone; // Default ke ikon Tim/Customer Service

    if (currentRouteName == '/home') {
      activeIcon = Icons.home;
    } else if (currentRouteName == '/checkout') {
      activeIcon = Icons.shopping_cart;
    } else if (currentRouteName == '/profile') {
      activeIcon = Icons.person;
    } else if (currentRouteName == '/team_page') { // Pastikan route name ini konsisten
      activeIcon = Icons.phone;
    }

    return BottomAppBar(
      color: Colors.transparent, // Membuat background BottomAppBar transparan
      elevation: 0, // Menghilangkan bayangan bawaan BottomAppBar
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Padding di sekitar container utama
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black, // Warna background BottomNavigationBar
            borderRadius: BorderRadius.circular(30), // Membuat sudut melengkung
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribusi item merata
            children: [
              _buildNavItem(Icons.phone, "Tim", context, currentUserName, currentUserEmail, isActive: activeIcon == Icons.phone),
              _buildNavItem(Icons.home, "Home", context, currentUserName, currentUserEmail, isActive: activeIcon == Icons.home),
              _buildNavItem(Icons.shopping_cart, "Keranjang", context, currentUserName, currentUserEmail, isActive: activeIcon == Icons.shopping_cart),
              _buildNavItem(Icons.person, "Profil", context, currentUserName, currentUserEmail, isActive: activeIcon == Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  // Modifikasi _buildNavItem untuk menerima nama dan email serta status isActive
  Widget _buildNavItem(IconData icon, String label, BuildContext context, String currentUserName, String currentUserEmail, {required bool isActive}) {
    return IconButton(
      icon: Icon(
        icon,
        // Jika item aktif (isActive == true), warnanya yellowColor (kuning cerah).
        // Jika tidak aktif, warnanya Color(0xFFF9D33C) (kuning pucat).
        // Ini sudah menggantikan penggunaan Colors.white untuk ikon aktif.
        color: isActive ? yellowColor : const Color(0xFFF9D33C),
        size: isActive ? 24 : 24, // Ukuran ikon sedikit lebih besar jika aktif
      ),
      tooltip: label, // Tooltip untuk aksesibilitas
      onPressed: () {
        // Hindari navigasi ke halaman yang sama jika sudah aktif
        if (isActive) return;

        if (icon == Icons.person) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/profile'), // Tambahkan RouteSettings
              builder: (_) => ProfileScreen(
              ),
            ),
          );
        } else if (icon == Icons.home) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/home'), // Tambahkan RouteSettings
              builder: (_) => HomeScreen(
                name: currentUserName,
                email: currentUserEmail,
                cart: widget.cart,
                orderHistory: widget.orderHistory,
              ),
            ),
          );
        } else if (icon == Icons.shopping_cart) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/checkout'), // Tambahkan RouteSettings
              builder: (_) => CheckoutScreen(
                name: currentUserName,
                email: currentUserEmail,
              ),
            ),
          );
        } else if (icon == Icons.phone) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/team_page'), // Tambahkan RouteSettings (sesuaikan nama route jika perlu)
              builder: (_) => TeamPage(
                cart: widget.cart,
                name: currentUserName,
                email: currentUserEmail,
                orderHistory: widget.orderHistory,
              ),
            ),
          );
        }
      },
    );
  }
}

// Widget ContactInfoTile tetap sama
class ContactInfoTile extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final Color iconBackgroundColor;
  final Color iconColor;

  const ContactInfoTile({
    Key? key,
    required this.iconData,
    required this.title,
    required this.subtitle,
    required this.iconBackgroundColor,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: iconBackgroundColor,
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}