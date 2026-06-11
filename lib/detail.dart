// detail.dart
import 'package:flutter/material.dart';

// --- PENJELASAN WIDGET ---
// DetailScreen adalah sebuah halaman (widget) yang bisa mengingat dan mengubah data di dalamnya.
// Contohnya, halaman ini bisa mengingat berapa jumlah produk yang sedang dipilih pengguna.
// Dalam Flutter, ini disebut StatefulWidget.
class DetailScreen extends StatefulWidget {
  // --- PENJELASAN PARAMETER ---
  // Halaman ini perlu menerima "paket data" dari halaman sebelumnya (misalnya dari daftar produk).
  // Paket data ini (`product`) berisi semua informasi tentang produk yang diklik oleh pengguna.
  final Map<String, dynamic> product;

  DetailScreen({required this.product});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

// --- PENJELASAN STATE CLASS ---
// Ini adalah "otak" dari halaman DetailScreen. Semua data yang bisa berubah dan logika halaman
// disimpan di sini.
class _DetailScreenState extends State<DetailScreen> {
  // Ini adalah "memori" untuk menyimpan jumlah produk. Nilai awalnya adalah 1.
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    // --- PENJELASAN PENGAMBILAN DATA ---
    // Di sini, kita "membongkar" paket data produk yang diterima dari halaman sebelumnya.
    // Tanda tanya `?` dan `??` adalah untuk keamanan.
    // Contoh: `?? 'Nama Produk Tidak Tersedia'` artinya "jika nama produk tidak ada di dalam paket,
    // tampilkan tulisan 'Nama Produk Tidak Tersedia' saja agar aplikasi tidak error".
    final String? productImage = widget.product['image'];
    final String productName = widget.product['name'] ?? 'Nama Produk Tidak Tersedia';
    final int productPrice = widget.product['price'] as int? ?? 0;
    // ID ini sangat penting, seperti nomor KTP untuk produk. ID ini didapat dari database.
    final String? productId = widget.product['id'] as String?;

    // --- PENJELASAN PENANGANAN ERROR ---
    // Ini adalah pemeriksaan keamanan yang sangat penting.
    // Jika karena suatu alasan ID produk tidak ada (kosong), halaman ini tidak bisa berfungsi.
    if (productId == null) {
      print("ERROR: ID produk kosong di DetailScreen.");
      // Ini adalah perintah khusus: "Flutter, setelah halaman ini selesai kamu gambar,
      // tolong langsung jalankan kode ini ya".
      // Ini cara aman untuk menampilkan notifikasi dan menutup halaman.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ID produk tidak ditemukan.')),
        );
        // Otomatis kembali ke halaman sebelumnya.
        Navigator.pop(context);
      });
      // Sambil menunggu proses di atas, tampilkan halaman error sederhana.
      return Scaffold(body: Center(child: Text("Error memuat detail produk.")));
    }

    // --- PENJELASAN TAMPILAN (UI) ---
    // Scaffold adalah kerangka dasar dari sebuah halaman di Flutter.
    return Scaffold(
      backgroundColor: Colors.black, // Warna latar belakang utama halaman.
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Membuat bar atas transparan.
        elevation: 0, // Menghilangkan bayangan di bawah bar atas.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFF9D33C)),
          // Saat tombol panah kembali ditekan, tutup halaman ini.
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Expanded membuat widget di dalamnya (yaitu Stack) mengisi semua sisa ruang yang ada di layar.
          Expanded(
            // Stack digunakan untuk menumpuk widget di atas satu sama lain.
            // Bayangkan seperti menumpuk kertas: ada kertas kuning di bawah, dan kertas foto di atasnya.
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Ini adalah "kertas kuning" di lapisan bawah untuk menampilkan detail produk.
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF9D33C),
                    // Membuat sudutnya melengkung hanya di bagian atas.
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  // Mendorong container kuning ini ke bawah sejauh 120 piksel,
                  // agar ada ruang untuk gambar produk di atasnya.
                  margin: EdgeInsets.only(top: 120),
                  // SingleChildScrollView membuat konten di dalamnya bisa di-scroll
                  // jika teks deskripsinya sangat panjang dan tidak muat di layar.
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Memberi jarak kosong setinggi 100 piksel dari atas container kuning.
                        // Tujuannya agar teks tidak tertutup oleh gambar produk yang ada di atas.
                        SizedBox(height: 100),

                        // Menampilkan nama dan harga produk.
                        Text(productName, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
                        SizedBox(height: 8),
                        Text("Rp $productPrice", style: TextStyle(fontSize: 25, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15),

                        // Menampilkan deskripsi produk.
                        Text(
                          widget.product['description'] ?? "Deskripsi tidak tersedia.",
                          style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),

                        // Teks bantuan cara memesan.
                        Text(
                          "Cara Memesan:\n"
                          "1. Pilih kuantitas yang diinginkan.\n"
                          "2. Klik tombol 'Masukkan Keranjang'.\n"
                          "3. Lanjutkan ke halaman checkout untuk pembayaran.",
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        SizedBox(height: 20),

                        // Bagian untuk memilih jumlah (kuantitas).
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.black),
                              onPressed: () {
                                // Hanya kurangi jika jumlah lebih dari 1.
                                if (quantity > 1) {
                                  // `setState` adalah perintah AJAIB.
                                  // Ini memberitahu Flutter: "Hei, data `quantity` sudah berubah!
                                  // Tolong gambar ulang bagian layar yang menampilkan angka ini."
                                  setState(() => quantity--);
                                }
                              },
                            ),
                            Text('$quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.black),
                              onPressed: () => setState(() => quantity++),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Baris yang berisi tombol "Chat" dan "Masukkan Keranjang".
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () { /* Fungsi chat bisa ditambahkan di sini */ },
                              child: Icon(Icons.chat, color: Colors.white),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  // --- INI FUNGSI UTAMA HALAMAN INI ---
                                  onPressed: () {
                                    // `Navigator.pop` artinya "kembali ke halaman sebelumnya".
                                    // Tapi di sini kita tidak hanya kembali, kita juga membawa "oleh-oleh".
                                    // Oleh-olehnya adalah sebuah paket data (Map) yang berisi semua
                                    // info produk DITAMBAH dengan jumlah (`quantity`) yang sudah dipilih pengguna.
                                    // Halaman sebelumnya (daftar produk) akan menerima "oleh-oleh" ini
                                    // dan menggunakannya untuk menambahkan produk ke keranjang belanja.
                                    Navigator.pop(context, {
                                      'id': productId,
                                      'name': productName,
                                      'price': productPrice,
                                      'image': productImage ?? '',
                                      'quantity': quantity,
                                      'category': widget.product['category'],
                                      'description': widget.product['description'],
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text("Masukkan Keranjang", style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Ini adalah "kertas foto" yang diletakkan di lapisan atas.
                Positioned(
                  top: 20,
                  // Hero membuat animasi keren seolah-olah gambar produk "terbang" dari
                  // halaman daftar ke halaman detail ini.
                  child: Hero(
                    // `tag` adalah "kode rahasia". Halaman daftar dan halaman detail
                    // harus punya Hero dengan `tag` yang sama (yaitu ID produk)
                    // agar animasi ini bisa berjalan.
                    tag: productId,
                    child: (productImage != null && productImage.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            // Memuat gambar dari internet.
                            child: Image.network(
                              productImage,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              // `loadingBuilder`: Menampilkan lingkaran putar-putar saat gambar sedang di-download.
                              loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(height: 200, width: 200, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))),
                              // `errorBuilder`: Menampilkan ikon "gambar rusak" jika gambar gagal dimuat.
                              errorBuilder: (ctx, err, trace) => Container(height: 200, width: 200, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)), child: Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey[600]))),
                            ),
                          )
                        // Jika produk tidak punya gambar, tampilkan kotak abu-abu.
                        : Container(height: 200, width: 200, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)), child: Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey[600]))),
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