import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

class OutletsScreen extends StatefulWidget {
  const OutletsScreen({super.key});
  @override
  State<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends State<OutletsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<OutletProvider>().load());
  }

  void _showCreate() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Outlet'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Outlet', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await context.read<OutletProvider>().create(ctrl.text);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _showRename(OutletInfo outlet) {
    final ctrl = TextEditingController(text: outlet.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Nama Outlet'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Baru', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await context.read<OutletProvider>().update(outlet.id, ctrl.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(OutletInfo outlet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red),
        title: const Text('Hapus Outlet'),
        content: Text('Hapus outlet "${outlet.name}"? Semua device terhubung akan terputus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<OutletProvider>().delete(outlet.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OutletProvider>();

    if (provider.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.successMessage!)));
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
        title: const Text('Outlet Saya'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.load()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreate,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Outlet'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.outlets.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada outlet', style: TextStyle(color: Colors.grey)),
                    Text('Tap tombol + untuk menambah outlet', style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.outlets.length,
                  itemBuilder: (_, i) {
                    final o = provider.outlets[i];
                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${o.deviceCount ?? 0} device • ${o.transactionCount ?? 0} transaksi'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Text('Kode Aktivasi: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(o.activationCode,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontFamily: 'monospace',
                                        letterSpacing: 2)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Salin kode',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: o.activationCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kode disalin!')));
                                  },
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showRename(o),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Ubah Nama'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(o),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Hapus'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ]),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
