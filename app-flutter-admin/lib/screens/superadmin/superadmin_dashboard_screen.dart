import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../utils/format_utils.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});
  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _confirmBan(SuperAdminUser user) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ban ${user.name}'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Alasan ban',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SuperAdminProvider>().banUser(
                  user.id, reasonCtrl.text.trim().isEmpty ? 'Banned oleh super admin' : reasonCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _confirmUnban(SuperAdminUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Unban ${user.name}?'),
        content: const Text('Akun user akan diaktifkan kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SuperAdminProvider>().unbanUser(user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Unban'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SuperAdminUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red),
        title: Text('Hapus ${user.name}?'),
        content: const Text('Data user beserta outlet dan transaksinya akan dihapus permanen!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SuperAdminProvider>().deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();
    final s = provider.stats;

    if (provider.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.message!)));
        provider.clearMessage();
      });
    }
    if (provider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
        provider.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadAll()),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Statistik'),
            Tab(text: 'Users'),
            Tab(text: 'OTP Requests'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                // Tab 1: Stats
                s == null
                    ? const Center(child: Text('Tidak ada data'))
                    : ListView(padding: const EdgeInsets.all(16), children: [
                        _StatRow('Total Users', s.totalUsers.toString(), Icons.people),
                        _StatRow('Total Outlets', s.totalOutlets.toString(), Icons.store),
                        _StatRow('Total Devices', s.totalDevices.toString(), Icons.devices),
                        _StatRow('Total Transaksi', s.totalTransactions.toString(), Icons.receipt_long),
                        _StatRow('OTP Requests', s.totalOtpRequests.toString(), Icons.mail),
                      ]),

                // Tab 2: Users
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.users.length,
                  itemBuilder: (_, i) {
                    final u = provider.users[i];
                    final isBanned = u.bannedPermanent || u.accountStatus == 'banned';
                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isBanned ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                          child: Icon(Icons.person, color: isBanned ? Colors.red : Colors.green),
                        ),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(u.email),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isBanned ? Colors.red : Colors.green).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isBanned ? 'Banned' : 'Aktif',
                              style: TextStyle(
                                  color: isBanned ? Colors.red : Colors.green,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Outlet: ${u.outletCount} • Device: ${u.deviceCount}',
                                  style: const TextStyle(color: Colors.grey)),
                              if (u.penaltyReason != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Alasan ban: ${u.penaltyReason}',
                                      style: const TextStyle(color: Colors.red)),
                                ),
                              if (u.createdAt != null)
                                Text('Bergabung: ${FormatUtils.formatDateShort(u.createdAt)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                if (!isBanned)
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmBan(u),
                                    icon: const Icon(Icons.block, size: 16),
                                    label: const Text('Ban'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmUnban(u),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: const Text('Unban'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(u),
                                  icon: const Icon(Icons.delete_forever, size: 16),
                                  label: const Text('Hapus'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ]),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Tab 3: OTP Requests
                provider.otpRequests.isEmpty
                    ? const Center(child: Text('Tidak ada OTP request'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.otpRequests.length,
                        itemBuilder: (_, i) {
                          final o = provider.otpRequests[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.mail_outline, color: Colors.orange),
                              title: Text(o.email),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (o.name != null) Text(o.name!),
                                Text('Kode: ${o.otpCode}',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        letterSpacing: 2)),
                                if (o.message != null) Text(o.message!, style: const TextStyle(color: Colors.grey)),
                                if (o.createdAt != null)
                                  Text(FormatUtils.formatDate(o.createdAt),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                              isThreeLine: true,
                            ),
                          );
                        }),
              ],
            ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatRow(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.red.shade700),
          title: Text(label),
          trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );
}
