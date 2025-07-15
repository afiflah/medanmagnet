import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'cart_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'chat_page.dart';

class HomeUserPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const HomeUserPage({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<HomeUserPage> createState() => _HomeUserPageState();
}

class _HomeUserPageState extends State<HomeUserPage> {
  int _currentCarousel = 0;
  bool _showAll = false;
  String selectedCategory = 'Semua';
  String searchQuery = '';

  final List<String> carouselImages = [
    'assets/cat.jpg',
    'assets/pipa.jpeg',
    'assets/besiBaja.jpeg',
  ];

  final List<String> categories = [
    'Semua',
    'Material Konstruksi',
    'Material Finishing',
    'Material Kayu & Olahan',
    'Material Atap',
    'Peralatan Bangunan',
    'Listrik & Elektrikal',
    'Pipa & Plumbing',
  ];

  List<dynamic> allProducts = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final data = await Supabase.instance.client.from('product').select();
    setState(() => allProducts = data);
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('user_id', widget.userId)
        .maybeSingle();
    return data;
  }

  Future<void> handleBuyProduct(Map<String, dynamic> product) async {
    final userProfile = await fetchUserProfile();

    if (userProfile == null || userProfile['alamat'] == null || userProfile['no_hp'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi profil Anda terlebih dahulu')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId)),
      );
      return;
    }

    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Beli Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Produk: ${product['name']}'),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Jumlah'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final int quantity = int.tryParse(qtyController.text) ?? 0;
              if (quantity <= 0 || quantity > product['quantity']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jumlah tidak valid atau melebihi stok')),
                );
                return;
              }

              final price = product['price'];
              final total = quantity * price;

              await Supabase.instance.client.from('orders').insert({
                'user_id': widget.userId,
                'product_id': product['id'],
                'quantity': quantity,
                'price': price,
                'total_price': total,
                'status': 'keranjang',
                'order_date': DateTime.now().toIso8601String(),
                'notes': notesController.text,
              });

              Navigator.pop(context);
              fetchProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesanan berhasil dibuat')),
              );
            },
            child: const Text('Beli'),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredProducts = allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final matchCategory = selectedCategory == 'Semua' || p['jenis'] == selectedCategory;
      return name.contains(searchQuery.toLowerCase()) && matchCategory;
    }).toList();

    final List<dynamic> productsToShow =
        _showAll ? filteredProducts : filteredProducts.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Bangunan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showProfileOptions,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartPage(userId: widget.userId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryPage(userId: widget.userId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatUserPage(
                  userId: widget.userId,
                  userRole: widget.userRole,
                ),
              ),
            ),
          ),
        ],
        
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true,
                enlargeCenterPage: true,
                onPageChanged: (index, _) => setState(() => _currentCarousel = index),
              ),
              items: carouselImages.map((imgPath) {
                return Image.asset(imgPath, fit: BoxFit.cover, width: double.infinity);
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: carouselImages.asMap().entries.map((entry) {
                return Container(
                  width: 10.0,
                  height: 10.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCarousel == entry.key ? Colors.blue : Colors.grey,
                  ),
                );
              }).toList(),
            ),
            // Search & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Produk Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Produk Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Text(_showAll ? 'Tampilkan Sedikit' : 'Lihat Semua'),
                      ),
                    ],
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.65,
                    children: productsToShow.map((product) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              product['image_url'] != null && product['image_url'].toString().isNotEmpty
                                  ? Image.network(
                                      product['image_url'],
                                      height: 60,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(Icons.shopping_bag, size: 40),
                              Text(
                                product['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              Text('Rp ${product['price']}'),
                              ElevatedButton(
                                onPressed: () => handleBuyProduct(product),
                                child: const Text('Beli'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
