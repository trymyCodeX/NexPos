import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Ganti Password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: oldCtrl,
              obscureText: obscureOld,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDs(() => obscureOld = !obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDs(() => obscureNew = !obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDs(() => obscureConfirm = !obscureConfirm),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password baru tidak cocok')));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password minimal 6 karakter')));
                  return;
                }
                Navigator.pop(context);
                final ok = await context.read<AuthProvider>().changePassword(
                    oldCtrl.text, newCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Password berhasil diubah!' : context.read<AuthProvider>().error ?? 'Gagal'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Saya'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'A',
                  style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(auth.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(auth.userEmail, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Owner', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Ganti Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePassword,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Versi Aplikasi'),
              trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onTap: _confirmLogout,
            ),
          ]),
        ),
      ]),
    );
  }
}
