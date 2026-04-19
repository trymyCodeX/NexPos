import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../transaction/transaction_list_screen.dart';
import '../transaction/create_transaction_screen.dart';
import '../master/services_screen.dart';
import '../master/customers_screen.dart';
import '../account/account_screen.dart';
import '../../models/transaction_models.dart';
import '../../utils/format_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _pollingTimer;
  TransactionProvider? _txProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProviders();
    });
  }

  void _initProviders() {
    final app = context.read<AppProvider>();
    if (app.txService != null && app.outletId != null) {
      _txProvider = TransactionProvider(app.txService!, app.outletId!);
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _txProvider?.loadTransactions(silent: true);
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (_txProvider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider.value(
      value: _txProvider!,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(txProvider: _txProvider!),
            const TransactionListScreen(),
            const CreateTransactionScreen(),
            const ServicesScreen(),
            const CustomersScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.list_outlined), selectedIcon: Icon(Icons.list), label: 'Transaksi'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Buat'),
            NavigationDestination(icon: Icon(Icons.local_laundry_service_outlined), selectedIcon: Icon(Icons.local_laundry_service), label: 'Layanan'),
            NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Pelanggan'),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => _selectedIndex = 2),
                icon: const Icon(Icons.add),
                label: const Text('Transaksi Baru'),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              )
            : null,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NexPos Laundry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                app.outletName ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Icon(
                    app.isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: app.isOnline ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    app.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: app.isOnline ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final TransactionProvider txProvider;

  const _HomeTab({required this.txProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final summary = provider.reportSummary;
        final recent = provider.transactions.take(5).toList();

        return RefreshIndicator(
          onRefresh: () => provider.loadAll(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (summary != null) ...[
                _SummaryCard(summary: summary),
                const SizedBox(height: 16),
              ],
              Text('Transaksi Terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (provider.isLoading && recent.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppTheme.gray500),
                        SizedBox(height: 8),
                        Text('Belum ada transaksi', style: TextStyle(color: AppTheme.gray500)),
                      ],
                    ),
                  ),
                )
              else
                ...recent.map((t) => _TransactionCard(transaction: t, provider: provider)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ReportSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatItem(label: 'Total Transaksi', value: summary.totalTransactions.toString(), color: AppTheme.primaryBlue)),
                Expanded(child: _StatItem(label: 'Pendapatan', value: FormatUtils.currency(summary.totalIncome), color: AppTheme.green)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _StatusBadge('Diterima', summary.totalDiterima, 'diterima'),
                _StatusBadge('Dicuci', summary.totalDicuci, 'dicuci'),
                _StatusBadge('Disetrika', summary.totalDisetrika, 'disetrika'),
                _StatusBadge('Selesai', summary.totalSelesai, 'selesai'),
                _StatusBadge('Batal', summary.totalDibatalkan, 'dibatalkan'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final String status;
  const _StatusBadge(this.label, this.count, this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 12, color: AppTheme.statusColor(status), fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionInfo transaction;
  final TransactionProvider provider;
  const _TransactionCard({required this.transaction, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.statusBgColor(transaction.status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppConstants.statusLabels[transaction.status] ?? transaction.status,
            style: TextStyle(fontSize: 11, color: AppTheme.statusColor(transaction.status), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(transaction.customer, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(transaction.service ?? '-'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(FormatUtils.currency(transaction.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            Text(FormatUtils.shortDate(transaction.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
          ],
        ),
      ),
    );
  }
}
