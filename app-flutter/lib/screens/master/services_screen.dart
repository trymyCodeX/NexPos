import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../models/transaction_models.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.loadServices,
            child: provider.services.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.local_laundry_service, size: 64, color: AppTheme.gray500),
                            SizedBox(height: 12),
                            Text('Belum ada layanan', style: TextStyle(color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.services.length,
                    itemBuilder: (context, i) {
                      final s = provider.services[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryBlueLight,
                            child: Icon(Icons.local_laundry_service, color: AppTheme.primaryBlue, size: 20),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            s.minQuantity != null
                                ? '${FormatUtils.currency(s.price.toDouble())} / ${s.unit}  •  min. ${s.minQuantity!.toStringAsFixed(s.minQuantity! % 1 == 0 ? 0 : 1)} ${s.unit}'
                                : '${FormatUtils.currency(s.price.toDouble())} / ${s.unit}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showServiceDialog(context, provider, service: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppTheme.red),
                                onPressed: () => _confirmDelete(context, provider, s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showServiceDialog(context, provider),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showServiceDialog(BuildContext context, TransactionProvider provider, {ServiceInfo? service}) {
    showDialog(
      context: context,
      builder: (_) => _ServiceDialog(provider: provider, service: service),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionProvider provider, ServiceInfo s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text('Yakin ingin menghapus layanan "${s.name}"?'),
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
      final ok = await provider.deleteService(s.id);
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Gagal')));
      }
    }
  }
}

class _ServiceDialog extends StatefulWidget {
  final TransactionProvider provider;
  final ServiceInfo? service;
  const _ServiceDialog({required this.provider, this.service});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _minQtyCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.service?.price.toString() ?? '');
    _unitCtrl = TextEditingController(text: widget.service?.unit ?? 'kg');
    final minQty = widget.service?.minQuantity;
    _minQtyCtrl = TextEditingController(
      text: minQty != null
          ? (minQty % 1 == 0 ? minQty.toInt().toString() : minQty.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _minQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Tambah Layanan' : 'Edit Layanan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Layanan')),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Satuan (kg, pcs, dll)')),
            const SizedBox(height: 8),
            TextField(
              controller: _minQtyCtrl,
              decoration: InputDecoration(
                labelText: 'Minimal Quantity (opsional)',
                hintText: 'Contoh: 3',
                helperText: 'Jika kurang dari minimal, harga dihitung dari minimal',
                helperMaxLines: 2,
                suffixText: _unitCtrl.text.trim().isEmpty ? 'unit' : _unitCtrl.text.trim(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    final unit = _unitCtrl.text.trim();
    final minQtyText = _minQtyCtrl.text.trim();
    final minQty = minQtyText.isEmpty ? null : double.tryParse(minQtyText);

    if (name.isEmpty) { setState(() => _error = 'Nama layanan wajib diisi'); return; }
    if (price <= 0) { setState(() => _error = 'Harga harus lebih dari 0'); return; }
    if (unit.isEmpty) { setState(() => _error = 'Satuan wajib diisi'); return; }
    if (minQtyText.isNotEmpty && (minQty == null || minQty <= 0)) {
      setState(() => _error = 'Minimal quantity harus lebih dari 0');
      return;
    }

    setState(() { _loading = true; _error = null; });

    bool ok;
    if (widget.service == null) {
      ok = await widget.provider.createService(name, price, unit, minQuantity: minQty);
    } else {
      ok = await widget.provider.updateService(widget.service!.id, name, price, unit, minQuantity: minQty);
    }

    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _error = widget.provider.error ?? 'Gagal');
      }
    }
  }
}
