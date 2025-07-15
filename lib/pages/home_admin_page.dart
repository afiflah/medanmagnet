import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../components/sidebar.dart';

class HomeAdminPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const HomeAdminPage({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  final supabase = Supabase.instance.client;

  int totalUsers = 0;
  int totalOrders = 0;
  int totalCanceled = 0;
  int totalRevenue = 0;

  List<Map<String, dynamic>> recentOrders = [];
  List<FlSpot> salesSpots = [];
  List<String> salesLabels = [];

  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() => isLoading = true);

      final userRes = await supabase
          .from('users')
          .select()
          .eq('role', 'user');

      final ordersRes = await supabase
          .from('orders')
          .select('*, users(username), product(name)')
          .neq('status', 'keranjang')
          .order('order_date', ascending: false);

      final completed = ordersRes.where((o) => o['status'] == 'selesai');
      final canceled = ordersRes.where((o) => o['status'] == 'dibatalkan');

      final Map<String, List<dynamic>> groupedTx = {};
      for (var o in ordersRes) {
        final tx = o['transaction_id'];
        if (tx != null) {
          groupedTx.putIfAbsent(tx, () => []).add(o);
        }
      }

      final recent = groupedTx.entries.take(5).map((entry) {
        final orders = entry.value;
        final username = orders.first['users']?['username'] ?? 'User';
        final date = orders.first['order_date'];
        final products = orders.map((x) => x['product']['name']).join(', ');
        final total = orders.fold(
            0, (sum, o) => sum + ((o['total_price'] ?? 0) as num).toInt());
        return {
          'username': username,
          'products': products,
          'date': date,
          'total': total,
        };
      }).toList();

      final Map<String, int> dailySales = {};
      for (var o in completed) {
        final date = DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(o['order_date']));
        dailySales[date] = (dailySales[date] ?? 0) +
            ((o['total_price'] ?? 0) as num).toInt();
      }

      final sortedDates = dailySales.keys.toList()..sort();
      salesSpots = [];
      salesLabels = [];
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final total = dailySales[date]!;
        salesSpots.add(FlSpot(i.toDouble(), total.toDouble()));
        salesLabels.add(DateFormat('dd/MM').format(DateTime.parse(date)));
      }

      if (!mounted) return;

      setState(() {
        totalUsers = userRes.length;
        totalOrders = ordersRes.length;
        totalCanceled = canceled.length;
        totalRevenue = completed.fold(
            0, (sum, o) => sum + ((o['total_price'] ?? 0) as num).toInt());
        recentOrders = recent;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Dashboard error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: AdminSidebar(userId: widget.userId, userRole: widget.userRole),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari nama user...',
                      ),
                      onChanged: (val) =>
                          setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 16),
                    _buildAreaChart(),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard('Total User', totalUsers, Colors.blue),
                        _buildStatCard('Total Pesanan', totalOrders, Colors.green),
                        _buildStatCard('Total Pendapatan', totalRevenue, Colors.orange),
                        _buildStatCard('Pesanan Dibatalkan', totalCanceled, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '5 Pesanan Terakhir',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...recentOrders
                        .where((o) => o['username']
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()))
                        .map((order) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.receipt),
                                title: Text(order['username']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order['products']),
                                    Text(DateFormat('dd MMM yyyy')
                                        .format(DateTime.parse(order['date']))),
                                  ],
                                ),
                                trailing: Text(
                                  'Rp ${order['total']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: salesSpots.isEmpty
              ? 10
              : salesSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= salesLabels.length) {
                    return const SizedBox();
                  }
                  return Text(salesLabels[index],
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: salesSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: false),
            )
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
