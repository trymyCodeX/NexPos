import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../models/transaction_models.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari pelanggan atau layanan...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: provider.setSearch,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadTransactions(),
                child: provider.isLoading && provider.transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.transactions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long, size: 64, color: AppTheme.gray500),
                                    SizedBox(height: 12),
                                    Text('Belum ada transaksi', style: TextStyle(color: AppTheme.gray500)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: provider.transactions.length,
                            itemBuilder: (context, index) {
                              final t = provider.transactions[index];
                              return _TransactionItem(transaction: t, provider: provider);
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionInfo transaction;
  final TransactionProvider provider;
  const _TransactionItem({required this.transaction, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: transaction, provider: provider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.customer,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.statusBgColor(transaction.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppConstants.statusLabels[transaction.status] ?? transaction.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.statusColor(transaction.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.service ?? '-',
                    style: const TextStyle(color: AppTheme.gray700),
                  ),
                  Text(
                    FormatUtils.currency(transaction.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.shortDate(transaction.createdAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
