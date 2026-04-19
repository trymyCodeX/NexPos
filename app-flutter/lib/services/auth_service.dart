import '../models/auth_models.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  final ApiService _api;
  final SessionService _session;

  AuthService(this._session) : _api = ApiService();

  Future<AuthResponse> loginDevice(String activationCode) async {
    final deviceId = await _session.getOrCreateDeviceId();
    final deviceName = 'Flutter Device';

    final request = DeviceLoginRequest(
      activationCode: activationCode.trim().toUpperCase(),
      deviceName: deviceName,
      deviceId: deviceId,
    );

    final data = await _api.post('${AppConstants.apiAuth}/login-device', request.toJson());
    final response = AuthResponse.fromJson(data);
    await _session.saveDeviceSession(response.token, response.outlet, response.device, deviceId);
    return response;
  }

  Future<AuthResponse> login(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    final data = await _api.post('${AppConstants.apiAuth}/login', request.toJson());
    final response = AuthResponse.fromJson(data);
    if (response.user != null) {
      await _session.saveAdminSession(response.token, response.user!);
    }
    return response;
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    final request = RegisterRequest(email: email, password: password, name: name);
    final data = await _api.post('${AppConstants.apiAuth}/register', request.toJson());
    final response = AuthResponse.fromJson(data);
    if (response.user != null) {
      await _session.saveAdminSession(response.token, response.user!);
    }
    return response;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('${AppConstants.apiAuth}/forgot-password', {'email': email});
  }

  Future<String> verifyOtp(String email, String otp) async {
    final data = await _api.post('${AppConstants.apiAuth}/verify-otp', {
      'email': email,
      'otp': otp,
    });
    return data['resetToken'] as String;
  }

  Future<void> resetPassword(String email, String resetToken, String newPassword) async {
    await _api.post('${AppConstants.apiAuth}/reset-password', {
      'email': email,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }

  Future<void> changePassword(String token, String currentPassword, String newPassword) async {
    final api = ApiService(token: token);
    await api.put('${AppConstants.apiAuth}/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _session.clearSession();
  }
}
