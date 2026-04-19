import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/format_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final filtered = provider.transactions.where((t) =>
        _search.isEmpty ||
        t.customerName.toLowerCase().contains(_search.toLowerCase()) ||
        t.outletName.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
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
