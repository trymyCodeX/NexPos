import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/format_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _logoTap = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<OutletProvider>().load();
    context.read<DeviceProvider>().load();
    context.read<TransactionProvider>().load();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
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
    final outlets = context.watch<OutletProvider>();
    final devices = context.watch<DeviceProvider>();
    final transactions = context.watch<TransactionProvider>();

    final totalRevenue = transactions.transactions.fold<num>(0, (sum, t) => sum + t.totalPrice);
    final activeDevices = devices.devices.where((d) => d.isActive).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: GestureDetector(
          onTap: () {
            _logoTap++;
            if (_logoTap >= 5) {
              _logoTap = 0;
              Navigator.pushNamed(context, '/superadmin');
            }
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NexPos Owners',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Selamat datang, ${auth.userName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Stats
          Row(children: [
            _StatCard('Outlet', outlets.outlets.length.toString(), Icons.store, Colors.blue),
            const SizedBox(width: 12),
            _StatCard('Device Aktif', activeDevices.toString(), Icons.devices, Colors.green),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _StatCard('Transaksi', transactions.transactions.length.toString(),
                Icons.receipt_long, Colors.orange),
            const SizedBox(width: 12),
            _StatCard('Total Pendapatan', FormatUtils.formatCurrency(totalRevenue),
                Icons.attach_money, Colors.purple),
          ]),
          const SizedBox(height: 24),
          // Menu Grid
          Text('Menu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _MenuCard('Outlet', Icons.store, Colors.blue,
                  () => Navigator.pushNamed(context, '/outlets').then((_) => _load())),
              _MenuCard('Device', Icons.devices, Colors.green,
                  () => Navigator.pushNamed(context, '/devices').then((_) => _load())),
              _MenuCard('Transaksi', Icons.receipt_long, Colors.orange,
                  () => Navigator.pushNamed(context, '/transactions').then((_) => _load())),
              _MenuCard('Laporan', Icons.bar_chart, Colors.purple,
                  () => Navigator.pushNamed(context, '/reports')),
              _MenuCard('Notifikasi', Icons.notifications, Colors.red,
                  () => Navigator.pushNamed(context, '/notifications')),
              _MenuCard('Akun', Icons.manage_accounts, Colors.teal,
                  () => Navigator.pushNamed(context, '/account')),
            ],
          ),
          const SizedBox(height: 24),
          // Recent outlets
          if (outlets.outlets.isNotEmpty) ...[
            Text('Outlet Saya', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...outlets.outlets.take(3).map((o) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.store)),
                    title: Text(o.name),
                    subtitle: Text('Kode: ${o.activationCode}'),
                    trailing: Text('${o.deviceCount ?? 0} device'),
                  ),
                )),
          ],
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
