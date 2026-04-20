import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/format_utils.dart';
import '../../models/admin_models.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TransactionProvider>().load());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return Colors.green;
      case 'dicuci': return Colors.blue;
      case 'disetrika': return Colors.purple;
      case 'dibatalkan': return Colors.red;
      default: return Colors.orange;
    }
  }

  // FIX: tampilkan detail + aksi saat transaksi di-tap
  void _showTransactionDetail(BuildContext context, TransactionInfo t, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TransactionDetailSheet(
        transaction: t,
        provider: provider,
        statusColor: _statusColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final filtered = provider.transactions.where((t) =>
        _search.isEmpty ||
        t.customerName.toLowerCase().contains(_search.toLowerCase()) ||
        t.outletName.toLowerCase().contains(_search.toLowerCase())).toList();

    // Tampilkan pesan/error sebagai snackbar
    if (provider.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.message!), backgroundColor: Colors.green));
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
        title: const Text('Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Log Transaksi',
            onPressed: () => Navigator.pushNamed(context, '/transaction-logs'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.load()),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari pelanggan atau outlet...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Tidak ada transaksi'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        return Card(
                          child: ListTile(
                            // FIX: tambah onTap untuk buka detail & aksi
                            onTap: () => _showTransactionDetail(context, t, provider),
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(t.status).withOpacity(0.2),
                              child: Icon(Icons.receipt_long, color: _statusColor(t.status)),
                            ),
                            title: Text(t.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${t.outletName} • ${FormatUtils.formatDateShort(t.createdAt)}'),
                            trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(FormatUtils.formatCurrency(t.totalPrice),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(t.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(t.status,
                                        style: TextStyle(
                                            color: _statusColor(t.status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ─── Bottom Sheet Detail + Aksi Transaksi ────────────────────────────────────
class _TransactionDetailSheet extends StatefulWidget {
  final TransactionInfo transaction;
  final TransactionProvider provider;
  final Color Function(String) statusColor;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.provider,
    required this.statusColor,
  });

  @override
  State<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  bool _isLoading = false;

  static const _validStatuses = [
    'diterima', 'dicuci', 'disetrika', 'selesai', 'dibatalkan'
  ];

  static const _statusLabels = {
    'diterima': 'Diterima',
    'dicuci': 'Dicuci',
    'disetrika': 'Disetrika',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
  };

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    final ok = await widget.provider.updateStatus(widget.transaction.id, newStatus);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red),
        title: const Text('Hapus Transaksi'),
        content: Text('Hapus transaksi ${widget.transaction.customerName} secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      final ok = await widget.provider.deleteTransaction(widget.transaction.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final otherStatuses = _validStatuses.where((s) => s != t.status).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Detail Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.statusColor(t.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabels[t.status] ?? t.status,
                  style: TextStyle(color: widget.statusColor(t.status), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow('ID Transaksi', '#${t.id}'),
          _InfoRow('Pelanggan', t.customerName),
          _InfoRow('Outlet', t.outletName),
          _InfoRow('Total', FormatUtils.formatCurrency(t.totalPrice)),
          _InfoRow('Tanggal', FormatUtils.formatDateShort(t.createdAt)),
          const Divider(height: 24),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ))
          else ...[
            // Ubah Status
            Text('Ubah Status:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: otherStatuses.map((s) => ElevatedButton(
                onPressed: () => _updateStatus(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.statusColor(s),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(_statusLabels[s] ?? s),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Hapus Transaksi
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Hapus Transaksi', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
        const Text(': '),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
