import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

final _api = ApiService();
final _session = SessionService();

// ─── Auth Provider ───────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  bool isLoggedIn = false;
  String userName = '';
  String userEmail = '';
  String userId = '';

  Future<void> checkSession() async {
    isLoggedIn = await _session.isLoggedIn();
    if (isLoggedIn) {
      userName = await _session.getName() ?? '';
      userEmail = await _session.getEmail() ?? '';
      userId = await _session.getUserId() ?? '';
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.post('/api/auth/login', {'email': email.trim(), 'password': password});
      final resp = LoginResponse.fromJson(data);
      await _session.saveSession(
        token: resp.token,
        name: resp.user.name,
        email: resp.user.email,
        userId: resp.user.id,
      );
      isLoggedIn = true;
      userName = resp.user.name;
      userEmail = resp.user.email;
      userId = resp.user.id;
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.statusCode == 401
          ? 'Email atau password salah'
          : e.statusCode == 403
              ? 'Akun Anda diblokir. Hubungi admin.'
              : e.message;
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Terjadi kesalahan, coba lagi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.post('/api/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      });
      final resp = LoginResponse.fromJson(data);
      await _session.saveSession(
        token: resp.token,
        name: resp.user.name,
        email: resp.user.email,
        userId: resp.user.id,
      );
      isLoggedIn = true;
      userName = resp.user.name;
      userEmail = resp.user.email;
      userId = resp.user.id;
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.statusCode == 409
          ? 'Email sudah terdaftar, silakan login'
          : e.message;
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Terjadi kesalahan, coba lagi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.post('/api/auth/forgot-password', {'email': email.trim()});
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      await _api.post(
        '/api/auth/change-password',
        {'oldPassword': oldPassword, 'newPassword': newPassword},
        token: token,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.statusCode == 401 ? 'Password lama tidak sesuai' : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _session.clearSession();
    isLoggedIn = false;
    userName = '';
    userEmail = '';
    userId = '';
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

// ─── Outlet Provider ─────────────────────────────────────────────────────────
class OutletProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? successMessage;
  List<OutletInfo> outlets = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final data = await _api.get('/api/outlets', token: token);
      outlets = (data['outlets'] as List? ?? [])
          .map((e) => OutletInfo.fromJson(e))
          .toList();
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }

  Future<bool> create(String name) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      await _api.post('/api/outlets', {'name': name.trim()}, token: token);
      successMessage = "Outlet '$name' berhasil dibuat!";
      await load();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.statusCode == 403
          ? 'Batas maksimal 5 outlet tercapai'
          : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int outletId, String name) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      await _api.put('/api/outlets/$outletId', {'name': name.trim()}, token: token);
      successMessage = 'Nama outlet berhasil diperbarui!';
      await load();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int outletId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      await _api.delete('/api/outlets/$outletId', token: token);
      successMessage = 'Outlet berhasil dihapus';
      await load();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    error = null;
    successMessage = null;
    notifyListeners();
  }
}

// ─── Device Provider ─────────────────────────────────────────────────────────
class DeviceProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? message;
  List<DeviceInfo> devices = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final data = await _api.get('/api/devices', token: token);
      devices = (data['devices'] as List? ?? [])
          .map((e) => DeviceInfo.fromJson(e))
          .toList();
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }

  Future<bool> forceLogout(String deviceId) async {
    try {
      final token = await _session.getToken();
      await _api.post('/api/devices/force-logout', {'deviceId': deviceId}, token: token);
      message = 'Device berhasil di-logout';
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rename(int id, String newName) async {
    try {
      final token = await _session.getToken();
      await _api.put('/api/devices/$id', {'deviceName': newName}, token: token);
      message = 'Nama device berhasil diubah';
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final token = await _session.getToken();
      await _api.delete('/api/devices/$id', token: token);
      message = 'Device berhasil dihapus';
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    error = null;
    message = null;
    notifyListeners();
  }
}

// ─── Transaction Provider ────────────────────────────────────────────────────
class TransactionProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<TransactionInfo> transactions = [];
  int? filterOutletId;

  Future<void> load({int? outletId}) async {
    isLoading = true;
    error = null;
    filterOutletId = outletId;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final path = outletId != null
          ? '/api/transactions?outletId=$outletId'
          : '/api/transactions';
      final data = await _api.get(path, token: token);
      transactions = (data['transactions'] as List? ?? [])
          .map((e) => TransactionInfo.fromJson(e))
          .toList();
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }
}

// ─── Report Provider ─────────────────────────────────────────────────────────
class ReportProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  ReportSummary? summary;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final data = await _api.get('/api/reports/summary', token: token);
      summary = ReportSummary.fromJson(data);
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }
}

// ─── Notification Provider ───────────────────────────────────────────────────
class NotificationProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? successMessage;
  List<NotificationInfo> notifications = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final data = await _api.get('/api/notifications', token: token);
      notifications = (data['notifications'] as List? ?? [])
          .map((e) => NotificationInfo.fromJson(e))
          .toList();
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }

  Future<bool> sendToOwner(String ownerId, String title, String message, String type) async {
    try {
      final token = await _session.getToken();
      await _api.post('/api/notifications', {
        'ownerId': ownerId,
        'title': title,
        'message': message,
        'type': type,
      }, token: token);
      successMessage = 'Notifikasi berhasil dikirim';
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    error = null;
    successMessage = null;
    notifyListeners();
  }
}

// ─── Transaction Log Provider ────────────────────────────────────────────────
class TransactionLogProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<TransactionLogInfo> logs = [];
  String? filterAction;

  Future<void> load({String? action}) async {
    isLoading = true;
    error = null;
    filterAction = action;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final queryParts = <String>[];
      if (action != null && action.isNotEmpty) queryParts.add('action=$action');
      queryParts.add('limit=200');
      final path = '/api/transaction-logs${queryParts.isNotEmpty ? '?${queryParts.join('&')}' : ''}';
      final data = await _api.get(path, token: token);
      logs = (data['logs'] as List? ?? [])
          .map((e) => TransactionLogInfo.fromJson(e))
          .toList();
      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }
}

// ─── SuperAdmin Provider ─────────────────────────────────────────────────────
class SuperAdminProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? message;
  String token = '';
  SuperAdminStats? stats;
  List<SuperAdminUser> users = [];
  List<OtpRequestInfo> otpRequests = [];

  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.post('/api/super-admin/login', {
        'username': username.trim(),
        'password': password,
      });
      token = data['token'] ?? '';
      isLoading = false;
      notifyListeners();
      await loadAll();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      error = e.statusCode == 401 ? 'Username atau password salah' : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final statsData = await _api.get('/api/super-admin/stats', token: token);
      stats = SuperAdminStats.fromJson(statsData);

      final usersData = await _api.get('/api/super-admin/users', token: token);
      users = (usersData['users'] as List? ?? [])
          .map((e) => SuperAdminUser.fromJson(e))
          .toList();

      final otpData = await _api.get('/api/super-admin/otp-requests', token: token);
      otpRequests = (otpData['requests'] as List? ?? [])
          .map((e) => OtpRequestInfo.fromJson(e))
          .toList();

      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      error = e.message;
      notifyListeners();
    }
  }

  Future<bool> banUser(String userId, String reason) async {
    try {
      await _api.post(
        '/api/super-admin/users/$userId/ban',
        {'reason': reason, 'permanent': true},
        token: token,
      );
      message = 'User berhasil diblokir';
      await loadAll();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unbanUser(String userId) async {
    try {
      await _api.post('/api/super-admin/users/$userId/unban', {}, token: token);
      message = 'User berhasil dibuka blokirnya';
      await loadAll();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _api.delete('/api/super-admin/users/$userId', token: token);
      message = 'User berhasil dihapus';
      await loadAll();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    token = '';
    stats = null;
    users = [];
    otpRequests = [];
    error = null;
    message = null;
    notifyListeners();
  }

  void clearMessage() {
    error = null;
    message = null;
    notifyListeners();
  }
}
