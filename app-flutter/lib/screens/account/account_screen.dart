import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _outletName;
  String? _outletCode;
  String? _deviceName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final session = context.read<AppProvider>().session;
    final outletName = await session.getOutletName();
    final outletCode = await session.getOutletCode();
    final deviceName = await session.getDeviceName();
    setState(() {
      _outletName = outletName;
      _outletCode = outletCode;
      _deviceName = deviceName;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informasi Outlet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(),
                        _InfoTile('Nama Outlet', _outletName ?? '-'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text('Kode Aktivasi', style: TextStyle(color: AppTheme.gray500)),
                            ),
                            const Text(': '),
                            Text(
                              _outletCode ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3),
                            ),
                            const SizedBox(width: 8),
                            if (_outletCode != null)
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _outletCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kode disalin!')),
                                  );
                                },
                              ),
                          ],
                        ),
                        _InfoTile('Nama Device', _deviceName ?? '-'),
                        _InfoTile('Status', app.isOnline ? 'Online' : 'Offline'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Ganti Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePassword(context, app),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, app),
                    icon: const Icon(Icons.logout, color: AppTheme.red),
                    label: const Text('Keluar dari Outlet', style: TextStyle(color: AppTheme.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.red)),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppProvider app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari outlet ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await app.logout();
    }
  }

  void _showChangePassword(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(app: app),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.gray500))),
          const Text(': '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AppProvider app;
  const _ChangePasswordDialog({required this.app});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password Lama'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password Baru'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty) {
      setState(() => _error = 'Semua field wajib diisi');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'Password baru minimal 6 karakter');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final authService = AuthService(widget.app.session);
      await authService.changePassword(widget.app.token!, current, newPass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui'), backgroundColor: AppTheme.green),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
}
