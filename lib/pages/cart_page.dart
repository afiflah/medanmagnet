import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CartPage extends StatefulWidget {
  final String userId;

  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;
  final uuid = Uuid();
  List<dynamic> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final data = await supabase
        .from('orders')
        .select('*, product(id, name, price, quantity)')
        .eq('user_id', widget.userId)
        .eq('status', 'keranjang');

    setState(() => cartItems = data);
  }

  Future<void> checkout() async {
    if (cartItems.isEmpty) return;

    String? metode = await showCheckoutDialog();

    if (metode == null) return; // User cancel

    final transactionId = uuid.v4();

    for (var item in cartItems) {
      final product = item['product'];
      final currentStock = product['quantity'];
      final orderedQty = item['quantity'];

      if (orderedQty > currentStock) {
        _showMessage('Stok ${product['name']} tidak cukup.');
        return;
      }

      // Kurangi stok produk
      await supabase
          .from('product')
          .update({'quantity': currentStock - orderedQty})
          .eq('id', product['id']);

      // Update pesanan
      await supabase.from('orders').update({
        'status': 'menunggu konfirmasi',
        'transaction_id': transactionId,
        'metode_pengambilan': metode,
      }).eq('id', item['id']);
    }

    await fetchCartItems();
    _showMessage('Checkout berhasil!');
  }

  Future<String?> showCheckoutDialog() async {
    String? selectedMethod = 'diambil';

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih metode pengambilan:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              items: const [
                DropdownMenuItem(value: 'diambil', child: Text('Diambil')),
                DropdownMenuItem(value: 'diantar', child: Text('Diantar')),
              ],
              onChanged: (value) => selectedMethod = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Checkout'),
            onPressed: () => Navigator.pop(context, selectedMethod),
          ),
        ],
      ),
    );
  }

  Future<void> deleteItem(dynamic item) async {
    await supabase.from('orders').delete().eq('id', item['id']);
    await fetchCartItems();
    _showMessage('Item berhasil dihapus');
  }

  Future<void> showEditDialog(dynamic item) async {
    final controller = TextEditingController(text: item['quantity'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Jumlah Pesanan'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(controller.text);
              if (newQty != null && newQty > 0) {
                await supabase
                    .from('orders')
                    .update({'quantity': newQty})
                    .eq('id', item['id']);
                await fetchCartItems();
                Navigator.pop(context);
                _showMessage('Jumlah diperbarui');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) =>
                        _buildCartItem(cartItems[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: checkout,
                    child: const Text('Checkout Sekarang'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['product']['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => showEditDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteItem(item),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Jumlah: ${item['quantity']}'),
            Text('Total Harga: Rp ${item['total_price']}'),
            Text(
              'Stok Tersisa: ${item['product']['quantity']}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
