import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/home_admin_page.dart';
import '../pages/manajemen_produk_page.dart';
import '../pages/manajemen_pesanan_page.dart';
import '../pages/chat_admin_page.dart';
import '../pages/auth_page.dart';

class AdminSidebar extends StatelessWidget {
  final String userId;
  final String userRole;

  const AdminSidebar({
    super.key,
    required this.userId,
    required this.userRole,
  });

  void _logout(BuildContext context) async {
    final supabase = Supabase.instance.client;
    // Optional logout Supabase session
    // await supabase.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                'Welcome, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  label: 'Home',
                  page: HomeAdminPage(userId: userId, userRole: userRole),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.shopping_bag,
                  label: 'Manajemen Produk',
                  page: ManajemenProdukPage(userId: userId, userRole: userRole),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long,
                  label: 'Manajemen Pesanan',
                  page: ManajemenPesananPage(userId: userId, userRole: userRole),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.chat,
                  label: 'Chat',
                  page: ChatAdminPage(userId: userId, userRole: userRole),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }
}
