import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/format_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ReportProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final s = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.load()),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(provider.error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => provider.load(), child: const Text('Coba Lagi')),
                  ]))
              : s == null
                  ? const Center(child: Text('Tidak ada data'))
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      Text('Ringkasan Keseluruhan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _StatCard('Total Transaksi', s.totalTransactions.toString(),
                            Icons.receipt_long, Colors.orange),
                        const SizedBox(width: 12),
                        _StatCard('Total Pendapatan', FormatUtils.formatCurrency(s.totalRevenue),
                            Icons.attach_money, Colors.green),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _StatCard('Total Pelanggan', s.totalCustomers.toString(),
                            Icons.people, Colors.blue),
                        const SizedBox(width: 12),
                        _StatCard('Selesai', s.completedCount.toString(),
                            Icons.check_circle, Colors.teal),
                      ]),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.orange.withOpacity(0.1),
                        child: ListTile(
                          leading: const Icon(Icons.pending_actions, color: Colors.orange),
                          title: const Text('Transaksi Pending'),
                          trailing: Text('${s.pendingCount}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),
                      ),
                      if (s.outletReports.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Per Outlet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...s.outletReports.map((o) => Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.store)),
                                title: Text(o.outletName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${o.transactionCount} transaksi'),
                                trailing: Text(FormatUtils.formatCurrency(o.revenue),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                            )),
                      ],
                    ]),
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
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ),
      );
}
