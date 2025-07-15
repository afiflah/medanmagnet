import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;
  Map<String, List<dynamic>> groupedOrders = {};
  String selectedStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _fetchGroupedOrders();
  }

  Future<void> _fetchGroupedOrders() async {
    try {
      // Mulai dari filter awal
      var query = supabase
          .from('orders')
          .select('*, product(name)')
          .eq('user_id', widget.userId)
          .neq('status', 'keranjang');

      // Tambahkan filter status jika bukan 'semua'
      if (selectedStatus != 'semua') {
        query = query.eq('status', selectedStatus);
      }

      // Setelah semua filter, baru order
      final data = await query.order('order_date');

      final Map<String, List<dynamic>> grouped = {};
      for (var order in data) {
        final txId = order['transaction_id'];
        if (txId != null) {
          grouped.putIfAbsent(txId, () => []).add(order);
        }
      }

      setState(() => groupedOrders = grouped);
    } catch (e) {
      print('❌ Error fetching orders: $e');
    }
  }

  Future<void> _printReceipt(List<dynamic> items) async {
    final pdf = pw.Document();
    final firstOrder = items.first;
    final orderDate = DateTime.parse(firstOrder['order_date']);
    final formattedDate = DateFormat('dd MMMM yyyy').format(orderDate);
    final formattedTime = DateFormat('HH:mm').format(orderDate);
    final total = items.fold<int>(
      0,
      (sum, item) => sum + ((item['total_price'] ?? 0) as num).toInt(),
    );

    final logo = await imageFromAssetBundle('assets/2.jpg');

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Image(logo, height: 80)),
            pw.SizedBox(height: 16),
            pw.Text('Struk Pesanan',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Tanggal: $formattedDate, $formattedTime'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Barang', 'Jumlah', 'Harga', 'Total'],
              data: items.map((item) {
                return [
                  item['product']['name'],
                  '${item['quantity']}',
                  'Rp ${item['price']}',
                  'Rp ${item['total_price']}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total: Rp $total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildTransactionTile(String txId, List<dynamic> orders) {
    final orderDate = DateTime.parse(orders.first['order_date']);
    final total = orders.fold<int>(
      0,
      (sum, item) => sum + ((item['total_price'] ?? 0) as num).toInt(),
    );
    final summary = orders.map((e) => e['product']['name']).join(', ');

    return ExpansionTile(
      title: Text('Transaksi: ${DateFormat('dd MMM yyyy').format(orderDate)}'),
      subtitle: Text(summary),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Rp $total', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Struk',
            onPressed: () => _printReceipt(orders),
          ),
        ],
      ),
      children: orders.map((item) {
        return ListTile(
          title: Text(item['product']['name']),
          subtitle: Text('Qty: ${item['quantity']}'),
          trailing: Text('Rp ${item['total_price']}'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      'semua',
      'menunggu konfirmasi',
      'diproses',
      'selesai',
      'dibatalkan'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Filter Status:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                      _fetchGroupedOrders();
                    }
                  },
                ),
              ],
            ),
          ),

          // Daftar Transaksi
          Expanded(
            child: groupedOrders.isEmpty
                ? const Center(child: Text('Belum ada riwayat pesanan'))
                : RefreshIndicator(
                    onRefresh: _fetchGroupedOrders,
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: groupedOrders.entries.map((entry) {
                        return _buildTransactionTile(entry.key, entry.value);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
