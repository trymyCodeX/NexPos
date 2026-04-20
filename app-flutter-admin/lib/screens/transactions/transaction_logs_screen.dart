import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../utils/format_utils.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});
  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}

class _TransactionLogsScreenState extends State<TransactionLogsScreen> {
  String _filterAction = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TransactionLogProvider>().load());
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'created': return Colors.green;
      case 'deleted': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'created': return Icons.add_circle_outline;
      case 'deleted': return Icons.delete_outline;
      default: return Icons.update;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'created': return 'Transaksi Masuk';
      case 'deleted': return 'Dihapus';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionLogProvider>();

    List<TransactionLogInfo> filtered = provider.logs.where((l) {
      if (_filterAction != 'all' && l.action != _filterAction) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return (l.customerName?.toLowerCase().contains(q) ?? false) ||
            (l.outletName?.toLowerCase().contains(q) ?? false) ||
            (l.serviceName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.load(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pelanggan, outlet, atau layanan...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filterAction == 'all',
                        color: Colors.grey.shade700,
                        onTap: () => setState(() => _filterAction = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Transaksi Masuk',
                        selected: _filterAction == 'created',
                        color: Colors.green,
                        onTap: () => setState(() => _filterAction = 'created'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Dihapus',
                        selected: _filterAction == 'deleted',
                        color: Colors.red,
                        onTap: () => setState(() => _filterAction = 'deleted'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats bar
          if (!provider.isLoading && provider.logs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  _StatBadge(
                    label: 'Total',
                    count: provider.logs.length,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 12),
                  _StatBadge(
                    label: 'Masuk',
                    count: provider.logs.where((l) => l.action == 'created').length,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatBadge(
                    label: 'Dihapus',
                    count: provider.logs.where((l) => l.action == 'deleted').length,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(provider.error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.load(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Belum ada log transaksi',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final log = filtered[i];
                              final actionColor = _actionColor(log.action);
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: actionColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: actionColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(_actionIcon(log.action), color: actionColor, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _actionLabel(log.action),
                                                  style: TextStyle(
                                                    color: actionColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            log.createdAt != null
                                                ? FormatUtils.formatDateShort(log.createdAt!)
                                                : '-',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (log.customerName != null)
                                                  Text(
                                                    log.customerName!,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                if (log.serviceName != null)
                                                  Text(
                                                    log.serviceName!,
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                                if (log.outletName != null)
                                                  Text(
                                                    'Outlet: ${log.outletName}',
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              if (log.totalAmount != null)
                                                Text(
                                                  FormatUtils.formatCurrency(log.totalAmount!),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: actionColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (log.quantity != null)
                                                Text(
                                                  '${log.quantity} unit',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            log.notes!,
                                            style: TextStyle(
                                              color: Colors.amber.shade800,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (log.transactionId != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'ID Transaksi: #${log.transactionId}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: $count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
