import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/transaction_models.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.loadCustomers,
            child: provider.customers.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.people, size: 64, color: AppTheme.gray500),
                            SizedBox(height: 12),
                            Text('Belum ada pelanggan', style: TextStyle(color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.customers.length,
                    itemBuilder: (context, i) {
                      final c = provider.customers[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlueLight,
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.phone.isNotEmpty) Text(c.phone),
                              if (c.address.isNotEmpty)
                                Text(c.address, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showDialog(context, provider, customer: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppTheme.red),
                                onPressed: () => _confirmDelete(context, provider, c),
                              ),
                            ],
                          ),
                          isThreeLine: c.address.isNotEmpty,
                        ),
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showDialog(context, provider),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  void _showDialog(BuildContext context, TransactionProvider provider, {CustomerInfo? customer}) {
    showDialog(
      context: context,
      builder: (_) => _CustomerDialog(provider: provider, customer: customer),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionProvider provider, CustomerInfo c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Yakin ingin menghapus pelanggan "${c.name}"?'),
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
      final ok = await provider.deleteCustomer(c.id);
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Gagal')));
      }
    }
  }
}

class _CustomerDialog extends StatefulWidget {
  final TransactionProvider provider;
  final CustomerInfo? customer;
  const _CustomerDialog({required this.provider, this.customer});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.customer?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Telepon (opsional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
              maxLines: 2,
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
    if (name.isEmpty) { setState(() => _error = 'Nama pelanggan wajib diisi'); return; }

    setState(() { _loading = true; _error = null; });

    bool ok;
    if (widget.customer == null) {
      ok = await widget.provider.createCustomer(name, _phoneCtrl.text.trim(), _addressCtrl.text.trim());
    } else {
      ok = await widget.provider.updateCustomer(widget.customer!.id, name, _phoneCtrl.text.trim(), _addressCtrl.text.trim());
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
