import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String userId; // Ambil user_id dari login
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isEditing = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (data == null) {
        print('⚠️ User belum ada di tabel users');
      } else {
        print('✅ Data user ditemukan: $data');
      }

      setState(() {
        userData = data;
        usernameController.text = data?['username'] ?? '';
        emailController.text = data?['email'] ?? '';
        alamatController.text = data?['alamat'] ?? '';
        noHpController.text = data?['no_hp']?.toString() ?? '';
      });
    } catch (e) {
      print('❌ Error fetch user: $e');
    }
  }

  Future<void> saveProfile() async {
    try {
      await Supabase.instance.client.from('users').upsert({
        'user_id': widget.userId,
        'username': usernameController.text,
        'email': emailController.text,
        'alamat': alamatController.text,
        'no_hp': int.tryParse(noHpController.text) ?? 0,
      });

      setState(() {
        isEditing = false;
        userData = {
          'username': usernameController.text,
          'email': emailController.text,
          'alamat': alamatController.text,
          'no_hp': int.tryParse(noHpController.text) ?? 0,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } catch (e) {
      print('❌ Error update profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: isEditing ? buildEditForm() : buildProfileView(),
            ),
    );
  }

  Widget buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/profile_placeholder.png'),
        ),
        const SizedBox(height: 20),
        Text(
          userData!['username'] ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        profileInfoTile(Icons.email, userData!['email'] ?? ''),
        profileInfoTile(Icons.location_on, userData!['alamat'] ?? 'Belum diisi'),
        profileInfoTile(Icons.phone, userData!['no_hp']?.toString() ?? 'Belum diisi'),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              isEditing = true;
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profil'),
        ),
      ],
    );
  }

  Widget buildEditForm() {
    return Form(
      child: ListView(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/profile_placeholder.png'),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: alamatController,
            decoration: const InputDecoration(labelText: 'Alamat'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: noHpController,
            decoration: const InputDecoration(labelText: 'No. HP'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveProfile,
            child: const Text('Simpan'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = false;
              });
            },
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget profileInfoTile(IconData icon, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value),
    );
  }
}
