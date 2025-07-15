import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../components/sidebar.dart';

class ManajemenPesananPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const ManajemenPesananPage({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ManajemenPesananPage> createState() => _ManajemenPesananPageState();
}

class _ManajemenPesananPageState extends State<ManajemenPesananPage> {
  final supabase = Supabase.instance.client;
  Map<String, List<dynamic>> groupedOrders = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final isAdmin = widget.userRole == 'admin';
      final baseQuery = supabase
          .from('orders')
          .select('*, product(name), users(username)');
      final query = isAdmin
          ? baseQuery
          : baseQuery.eq('user_id', widget.userId);

      final data = await query
          .neq('status', 'keranjang')
          .order('order_date');

      final Map<String, List<dynamic>> grouped = {};
      for (final item in data) {
        final txId = item['transaction_id'];
        if (txId != null) {
          grouped.putIfAbsent(txId, () => []).add(item);
        }
      }

      setState(() => groupedOrders = grouped);
    } catch (e) {
      print('❌ Error fetching orders: $e');
    }
  }

  Future<void> updateOrderStatusByTransaction(String txId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('transaction_id', txId);

      await fetchOrders();
    } catch (e) {
      print('❌ Error updating order status: $e');
    }
  }

  Widget buildOrderGroup(String txId, List<dynamic> items) {
    final date = DateTime.tryParse(items.first['order_date'] ?? '') ?? DateTime.now();
    final username = items.first['users']?['username'] ?? 'Tidak Diketahui';
    final status = items.first['status'] ?? '-';
    final metode = items.first['metode_pengambilan'] ?? '-';
    final summary = items.map((e) => e['product']['name']).join(', ');
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (item['total_price'] ?? 0) as int,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Transaksi: ${DateFormat('dd MMM yyyy').format(date)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemesan: $username'),
            Text('Status: $status'),
            Text('Metode: $metode'),
            Text('Produk: $summary'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.edit),
          tooltip: 'Ubah status pesanan',
          onSelected: (value) => updateOrderStatusByTransaction(txId, value),
          itemBuilder: (context) => [
            'pending',
            'diproses',
            'selesai',
            'dibatalkan',
          ].map((status) => PopupMenuItem(
                value: status,
                child: Text(status),
              )).toList(),
        ),
        children: [
          ...items.map((item) => ListTile(
                title: Text(item['product']['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty: ${item['quantity']}'),
                    Text('Harga: Rp ${item['total_price']}'),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: Rp $total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = groupedOrders.entries.where((entry) {
      final username = (entry.value.first['users']?['username'] ?? '').toLowerCase();
      return username.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Pesanan')),
      drawer: AdminSidebar(
        userId: widget.userId,
        userRole: widget.userRole,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama pemesan...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: groupedOrders.isEmpty
                  ? const Center(child: Text('Tidak ada pesanan.'))
                  : RefreshIndicator(
                      onRefresh: fetchOrders,
                      child: ListView(
                        children: filteredEntries
                            .map((entry) =>
                                buildOrderGroup(entry.key, entry.value))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
