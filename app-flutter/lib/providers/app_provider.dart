import 'package:flutter/foundation.dart';
  import '../services/session_service.dart';
  import '../services/auth_service.dart';
  import '../services/transaction_service.dart';
  import '../services/device_service.dart';
  import '../models/auth_models.dart';
  import '../models/transaction_models.dart';

  enum AuthStatus { unknown, authenticated, unauthenticated }

  class AppProvider extends ChangeNotifier {
    final SessionService _session = SessionService();
    late AuthService _authService;
    TransactionService? _txService;
    DeviceService? _deviceService;

    AuthStatus _authStatus = AuthStatus.unknown;
    String? _token;
    String? _outletName;
    int? _outletId;
    String? _deviceId;
    bool _isOnline = false;

    AuthStatus get authStatus => _authStatus;
    String? get token => _token;
    String? get outletName => _outletName;
    int? get outletId => _outletId;
    String? get deviceId => _deviceId;
    bool get isOnline => _isOnline;
    TransactionService? get txService => _txService;
    DeviceService? get deviceService => _deviceService;
    SessionService get session => _session;

    AppProvider() {
      _authService = AuthService(_session);
      _init();
    }

    Future<void> _init() async {
      final loggedIn = await _session.isLoggedIn();
      if (loggedIn) {
        _token = await _session.getToken();
        _outletName = await _session.getOutletName();
        _outletId = await _session.getOutletId();
        _deviceId = await _session.getDeviceId();
        if (_token != null) {
          _txService = TransactionService(_token!);
          _deviceService = DeviceService(_token!, _session);
          _authStatus = AuthStatus.authenticated;
          _deviceService!.startHeartbeat();
          _isOnline = true;
        }
      } else {
        _authStatus = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }

    Future<void> loginDevice(String activationCode) async {
      final response = await _authService.loginDevice(activationCode);
      _token = response.token;
      _outletName = response.outlet?.name;
      _outletId = response.outlet?.id;
      _deviceId = await _session.getDeviceId();
      _txService = TransactionService(_token!);
      _deviceService = DeviceService(_token!, _session);
      _authStatus = AuthStatus.authenticated;
      _deviceService!.startHeartbeat();
      _isOnline = true;
      notifyListeners();
    }

    Future<void> logout() async {
      _deviceService?.stopHeartbeat();
      await _authService.logout();
      _token = null;
      _outletName = null;
      _outletId = null;
      _txService = null;
      _deviceService = null;
      _isOnline = false;
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }

    void setOnlineStatus(bool online) {
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }
    }
  }

  class TransactionProvider extends ChangeNotifier {
    final TransactionService _service;
    final int outletId;

    List<TransactionInfo> _transactions = [];
    List<ServiceInfo> _services = [];
    List<CustomerInfo> _customers = [];
    ReportSummary? _reportSummary;

    bool _isLoading = false;
    String? _error;
    String _searchQuery = '';

    List<TransactionInfo> get transactions => _searchQuery.isEmpty
        ? _transactions
        : _transactions.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.customer.toLowerCase().contains(q) ||
                (t.service?.toLowerCase().contains(q) ?? false);
          }).toList();

    List<ServiceInfo> get services => _services;
    List<CustomerInfo> get customers => _customers;
    ReportSummary? get reportSummary => _reportSummary;
    bool get isLoading => _isLoading;
    String? get error => _error;
    String get searchQuery => _searchQuery;

    TransactionProvider(this._service, this.outletId) {
      loadAll();
    }

    void setSearch(String query) {
      _searchQuery = query;
      notifyListeners();
    }

    Future<void> loadAll() async {
      await Future.wait([loadTransactions(), loadServices(), loadCustomers(), loadSummary()]);
    }

    Future<void> loadTransactions({bool silent = false}) async {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }
      try {
        _transactions = await _service.getTransactions(outletId: outletId);
        _error = null;
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<void> loadServices() async {
      try {
        _services = await _service.getServices(outletId);
      } catch (_) {}
      notifyListeners();
    }

    Future<void> loadCustomers() async {
      try {
        _customers = await _service.getCustomers(outletId);
      } catch (_) {}
      notifyListeners();
    }

    Future<void> loadSummary() async {
      try {
        _reportSummary = await _service.getReportSummary(outletId: outletId);
      } catch (_) {}
      notifyListeners();
    }

    // BUG FIX: quantity diubah menjadi double untuk mendukung layanan berbasis berat
    // Sebelumnya int sehingga nilai 2.5 kg akan menjadi 2, menghasilkan harga yang salah
    Future<bool> createTransaction(String customerId, String serviceId, double quantity) async {
      try {
        await _service.createTransaction(CreateTransactionRequest(
          outletId: outletId,
          customerId: customerId,
          serviceId: serviceId,
          quantity: quantity,
        ));
        await loadTransactions(silent: true);
        await loadSummary();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> updateStatus(String transactionId, String status) async {
      try {
        await _service.updateStatus(transactionId, status);
        await loadTransactions(silent: true);
        await loadSummary();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteTransaction(String id) async {
      try {
        await _service.deleteTransaction(id);
        await loadTransactions(silent: true);
        await loadSummary();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> createService(String name, int price, String unit, {double? minQuantity}) async {
      try {
        await _service.createService(outletId, name, price, unit, minQuantity: minQuantity);
        await loadServices();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> updateService(String id, String name, int price, String unit, {double? minQuantity}) async {
      try {
        await _service.updateService(id, name, price, unit, minQuantity: minQuantity);
        await loadServices();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteService(String id) async {
      try {
        await _service.deleteService(id);
        await loadServices();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> createCustomer(String name, String phone, String address) async {
      try {
        await _service.createCustomer(outletId, name, phone, address);
        await loadCustomers();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> updateCustomer(String id, String name, String phone, String address) async {
      try {
        await _service.updateCustomer(id, name, phone, address);
        await loadCustomers();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteCustomer(String id) async {
      try {
        await _service.deleteCustomer(id);
        await loadCustomers();
        return true;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    void clearError() {
      _error = null;
      notifyListeners();
    }
  }
  