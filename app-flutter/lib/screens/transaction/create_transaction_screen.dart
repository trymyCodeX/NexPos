import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../models/transaction_models.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  CustomerInfo? _selectedCustomer;
  ServiceInfo? _selectedService;
  final _qtyController = TextEditingController(text: '1');
  bool _isLoading = false;
  String? _error;
  String _customerSearch = '';
  String _serviceSearch = '';

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double get _effectiveQty {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final minQty = _selectedService?.minQuantity;
    if (minQty != null && qty < minQty && qty > 0) return minQty;
    return qty;
  }

  double get _total {
    return (_selectedService?.price ?? 0) * _effectiveQty;
  }

  bool get _isMinQtyApplied {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final minQty = _selectedService?.minQuantity;
    return minQty != null && qty > 0 && qty < minQty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final filteredCustomers = provider.customers.where((c) {
          final q = _customerSearch.toLowerCase();
          return q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q);
        }).toList();

        final filteredServices = provider.services.where((s) {
          final q = _serviceSearch.toLowerCase();
          return q.isEmpty || s.name.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat Transaksi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Customer selection
              Text('Pilih Pelanggan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari pelanggan...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (v) => setState(() => _customerSearch = v),
              ),
              const SizedBox(height: 8),
              if (provider.customers.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: AppTheme.orange),
                    title: Text('Belum ada pelanggan. Tambah dulu di tab Pelanggan.'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: filteredCustomers.take(5).map((c) => RadioListTile<CustomerInfo>(
                      value: c,
                      groupValue: _selectedCustomer,
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                      title: Text(c.name),
                      subtitle: c.phone.isNotEmpty ? Text(c.phone) : null,
                      dense: true,
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 16),

              // Service selection
              Text('Pilih Layanan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari layanan...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (v) => setState(() => _serviceSearch = v),
              ),
              const SizedBox(height: 8),
              if (provider.services.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: AppTheme.orange),
                    title: Text('Belum ada layanan. Tambah dulu di tab Layanan.'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: filteredServices.take(5).map((s) => RadioListTile<ServiceInfo>(
                      value: s,
                      groupValue: _selectedService,
                      onChanged: (v) => setState(() => _selectedService = v),
                      title: Text(s.name),
                      subtitle: Text('${FormatUtils.currency(s.price.toDouble())} / ${s.unit}'),
                      dense: true,
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 16),

              // Quantity
              Text('Jumlah (${_selectedService?.unit ?? 'unit'})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final curr = int.tryParse(_qtyController.text) ?? 1;
                      if (curr > 1) setState(() => _qtyController.text = (curr - 1).toString());
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final curr = int.tryParse(_qtyController.text) ?? 1;
                      setState(() => _qtyController.text = (curr + 1).toString());
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total
              if (_selectedService != null && _selectedCustomer != null)
                Column(
                  children: [
                    if (_isMinQtyApplied)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.orange.withOpacity(0.4)),
                        ),
                        child: Text(
                          'Input ${_qtyController.text} ${_selectedService!.unit}, minimal ${_selectedService!.minQuantity!.toStringAsFixed(_selectedService!.minQuantity! % 1 == 0 ? 0 : 1)} ${_selectedService!.unit}. Harga dihitung dari minimal.',
                          style: const TextStyle(color: AppTheme.orange, fontSize: 12),
                        ),
                      ),
                    Card(
                      color: AppTheme.primaryBlueLight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pelanggan: ${_selectedCustomer!.name}', style: const TextStyle(color: AppTheme.primaryBlue)),
                                Text('Layanan: ${_selectedService!.name}', style: const TextStyle(color: AppTheme.primaryBlue)),
                                if (_isMinQtyApplied)
                                  Text(
                                    'Qty efektif: ${_effectiveQty.toStringAsFixed(_effectiveQty % 1 == 0 ? 0 : 1)} ${_selectedService!.unit}',
                                    style: const TextStyle(color: AppTheme.orange, fontSize: 12),
                                  ),
                              ],
                            ),
                            Text(
                              FormatUtils.currency(_total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.redLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.red)),
                ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _selectedCustomer == null || _selectedService == null
                      ? null
                      : () => _submit(provider),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.receipt),
                  label: Text(_isLoading ? 'Memproses...' : 'Buat Transaksi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(TransactionProvider provider) async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'Jumlah harus lebih dari 0');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await provider.createTransaction(
      _selectedCustomer!.id,
      _selectedService!.id,
      qty, // server akan handle min_quantity
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() {
          _selectedCustomer = null;
          _selectedService = null;
          _qtyController.text = '1';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dibuat!'), backgroundColor: AppTheme.green),
        );
      } else {
        setState(() => _error = provider.error ?? 'Gagal membuat transaksi');
      }
    }
  }
}
