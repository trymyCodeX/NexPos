import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class LoginDeviceScreen extends StatefulWidget {
  const LoginDeviceScreen({super.key});

  @override
  State<LoginDeviceScreen> createState() => _LoginDeviceScreenState();
}

class _LoginDeviceScreenState extends State<LoginDeviceScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Kode aktivasi minimal 4 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AppProvider>().loginDevice(code);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.vpn_key,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'NexPos Laundry',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi Kasir Outlet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.gray700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan kode aktivasi outlet yang diberikan oleh owner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kode Aktivasi',
                  hintText: 'Contoh: ABCD1234',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                onChanged: (v) {
                  _codeController.value = _codeController.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(offset: v.length),
                  );
                },
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.redLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.red),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Masuk ke Outlet', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.gray500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kode aktivasi didapat dari owner melalui aplikasi NexPos Admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.gray700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
