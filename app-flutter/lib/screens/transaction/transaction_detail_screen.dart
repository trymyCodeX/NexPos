import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../models/transaction_models.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionInfo transaction;
  final TransactionProvider provider;

  const TransactionDetailScreen({super.key, required this.transaction, required this.provider});

  @override
  Widget build(BuildContext context) {
    final nextStatuses = _getNextStatuses(transaction.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transaksi #${transaction.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusBgColor(transaction.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppConstants.statusLabels[transaction.status] ?? transaction.status,
                            style: TextStyle(
                              color: AppTheme.statusColor(transaction.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Pelanggan', transaction.customer),
                    _InfoRow('Layanan', transaction.service ?? '-'),
                    _InfoRow('Total', FormatUtils.currency(transaction.amount)),
                    _InfoRow('Dibuat', FormatUtils.fullDate(transaction.createdAt)),
                    if (transaction.updatedAt != null)
                      _InfoRow('Diperbarui', FormatUtils.fullDate(transaction.updatedAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (nextStatuses.isNotEmpty) ...[
              Text('Ubah Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nextStatuses.map((s) => _StatusButton(
                  status: s,
                  transaction: transaction,
                  provider: provider,
                  onDone: () => Navigator.pop(context),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            if (transaction.status != 'selesai' && transaction.status != 'dibatalkan')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                  label: const Text('Hapus Transaksi', style: TextStyle(color: AppTheme.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _getNextStatuses(String current) {
    const flow = ['diterima', 'dicuci', 'disetrika', 'selesai'];
    if (current == 'dibatalkan' || current == 'selesai') return [];
    final idx = flow.indexOf(current);
    final result = <String>[];
    if (idx >= 0 && idx < flow.length - 1) result.add(flow[idx + 1]);
    if (current != 'dibatalkan') result.add('dibatalkan');
    return result;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final success = await provider.deleteTransaction(transaction.id);
      if (context.mounted) {
        if (success) Navigator.pop(context);
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Gagal hapus')));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.gray500))),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatusButton extends StatefulWidget {
  final String status;
  final TransactionInfo transaction;
  final TransactionProvider provider;
  final VoidCallback onDone;
  const _StatusButton({required this.status, required this.transaction, required this.provider, required this.onDone});

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _update,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.statusColor(widget.status),
        foregroundColor: Colors.white,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(AppConstants.statusLabels[widget.status] ?? widget.status),
    );
  }

  Future<void> _update() async {
    setState(() => _loading = true);
    final success = await widget.provider.updateStatus(widget.transaction.id, widget.status);
    if (mounted) {
      setState(() => _loading = false);
      if (success) widget.onDone();
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.provider.error ?? 'Gagal')));
    }
  }
}
