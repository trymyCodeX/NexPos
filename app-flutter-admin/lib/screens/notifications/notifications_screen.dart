import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/format_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<NotificationProvider>().load());
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning': return Icons.warning_amber;
      case 'error': return Icons.error_outline;
      case 'success': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'warning': return Colors.orange;
      case 'error': return Colors.red;
      case 'success': return Colors.green;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    if (provider.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.successMessage!)));
        provider.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.load()),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (_, i) {
                    final n = provider.notifications[i];
                    return Card(
                      color: n.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      child: ListTile(
                        leading: Icon(_typeIcon(n.type), color: _typeColor(n.type)),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.message),
                          Text(FormatUtils.formatDate(n.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        isThreeLine: true,
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                )),
                      ),
                    );
                  }),
    );
  }
}
