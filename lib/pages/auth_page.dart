import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_admin_page.dart';
import 'home_user_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final supabase = Supabase.instance.client;

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password);

      if (data.isNotEmpty) {
        final user = data.first;
        final userId = user['user_id'];
        final role = user['role'];

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeAdminPage(userId: userId, userRole: role),
            ),
          );
        } else if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeUserPage(userId: userId, userRole: role),
            ),
          );
        } else {
          _showMessage('Role tidak dikenal!');
        }
      } else {
        _showMessage('Login gagal! Username atau Password salah.');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan saat login.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleRegister() async {
    setState(() => isLoading = true);
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final email = emailController.text.trim();

    try {
      await supabase.from('users').insert({
        'username': username,
        'password': password,
        'email': email,
        'role': 'user',
      });

      _showMessage('Registrasi berhasil! Silakan login.');

      setState(() {
        isLogin = true;
        usernameController.clear();
        passwordController.clear();
        emailController.clear();
      });
    } catch (e) {
      _showMessage('Terjadi kesalahan saat registrasi.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showResetPasswordForm() {
    final TextEditingController resetUsernameController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: resetUsernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'Password Baru'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final username = resetUsernameController.text.trim();
              final newPassword = newPasswordController.text.trim();

              if (username.isEmpty || newPassword.isEmpty) {
                _showMessage('Semua field wajib diisi!');
                return;
              }

              try {
                final user = await supabase
                    .from('users')
                    .select()
                    .eq('username', username)
                    .maybeSingle();

                if (user != null) {
                  await supabase
                      .from('users')
                      .update({'password': newPassword})
                      .eq('username', username);

                  Navigator.pop(context);
                  _showMessage('Password berhasil direset.');
                } else {
                  _showMessage('Username tidak ditemukan.');
                }
              } catch (e) {
                _showMessage('Gagal reset password.');
              }
            },
            child: const Text('Simpan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isWide
                  ? Row(
                      key: ValueKey(isLogin),
                      children: [
                        if (isLogin)
                          Expanded(child: imageSection(isDark, 'assets/1.jpg', 'Selamat Datang Kembali!')),
                        Expanded(child: buildForm()),
                        if (!isLogin)
                          Expanded(child: imageSection(isDark, 'assets/2.jpg', 'Bergabunglah Bersama Kami!')),
                      ],
                    )
                  : SingleChildScrollView(
                      key: ValueKey(isLogin),
                      child: Column(
                        children: [
                          imageSection(
                            isDark,
                            isLogin ? 'assets/1.jpg' : 'assets/2.jpeg',
                            isLogin ? 'Selamat Datang Kembali!' : 'Bergabunglah Bersama Kami!',
                          ),
                          buildForm(),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget imageSection(bool isDark, String imagePath, String text) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.blue[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 150),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildForm() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLogin ? 'Login' : 'Register',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          if (isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: showResetPasswordForm,
                child: const Text('Lupa Password?'),
              ),
            ),
          if (!isLogin)
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : (isLogin ? handleLogin : handleRegister),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isLogin ? 'Login' : 'Register'),
          ),
          TextButton(
            onPressed: () => setState(() => isLogin = !isLogin),
            child: Text(isLogin ? 'Belum punya akun? Register' : 'Sudah punya akun? Login'),
          ),
        ],
      ),
    );
  }
}
