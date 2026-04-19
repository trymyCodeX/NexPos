import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../utils/format_utils.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<DeviceProvider>().load());
  }

  void _confirmForceLogout(DeviceInfo device) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Force Logout Device'),
        content: Text("Paksa logout device '${device.deviceName}'? Device harus login ulang."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<DeviceProvider>().forceLogout(device.deviceId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Force Logout'),
          ),
        ],
      ),
    );
  }

  void _showRename(DeviceInfo device) {
    final ctrl = TextEditingController(text: device.deviceName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Nama Device'),
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
              await context.read<DeviceProvider>().rename(device.id, ctrl.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DeviceInfo device) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red),
        title: const Text('Hapus Device'),
        content: Text("Hapus device '${device.deviceName}' secara permanen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<DeviceProvider>().delete(device.id);
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
    final provider = context.watch<DeviceProvider>();

    if (provider.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.message!)));
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

    final active = provider.devices.where((d) => d.isActive).toList();
    final inactive = provider.devices.where((d) => !d.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Device'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.load()),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.devices.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.devices_other, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada device terdaftar', style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (active.isNotEmpty) ...[
                    _SectionHeader('Device Aktif (${active.length})', Colors.green),
                    ...active.map((d) => _DeviceCard(d, _confirmForceLogout, _showRename, _confirmDelete)),
                    const SizedBox(height: 16),
                  ],
                  if (inactive.isNotEmpty) ...[
                    _SectionHeader('Device Tidak Aktif (${inactive.length})', Colors.grey),
                    ...inactive.map((d) => _DeviceCard(d, _confirmForceLogout, _showRename, _confirmDelete)),
                  ],
                ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionHeader(this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      );
}

class _DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  final Function(DeviceInfo) onForceLogout;
  final Function(DeviceInfo) onRename;
  final Function(DeviceInfo) onDelete;
  const _DeviceCard(this.device, this.onForceLogout, this.onRename, this.onDelete);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: device.isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(Icons.phone_android, color: device.isActive ? Colors.green : Colors.grey),
        ),
        title: Text(device.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${device.outletName} • ${device.isActive ? "Aktif" : "Tidak aktif"}'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Device ID: ${device.deviceId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (device.lastSeen != null)
                Text('Terakhir aktif: ${FormatUtils.formatDate(device.lastSeen)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (device.isActive)
                  OutlinedButton.icon(
                    onPressed: () => onForceLogout(device),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Force Logout'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                OutlinedButton.icon(
                  onPressed: () => onRename(device),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Ubah Nama'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onDelete(device),
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
  }
}
