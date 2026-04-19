import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/auth_models.dart';

class SessionService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyOutletId = 'outlet_id';
  static const String _keyOutletName = 'outlet_name';
  static const String _keyOutletCode = 'outlet_code';
  static const String _keyDeviceId = 'device_id';
  static const String _keyDeviceName = 'device_name';
  static const String _keyDeviceDbId = 'device_db_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> getOrCreateDeviceId() async {
    final p = await prefs;
    final existing = p.getString(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    const uuid = Uuid();
    final newId = uuid.v4();
    await p.setString(_keyDeviceId, newId);
    return newId;
  }

  Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(_keyToken);
  }

  Future<int?> getOutletId() async {
    final p = await prefs;
    return p.getInt(_keyOutletId);
  }

  Future<String?> getOutletName() async {
    final p = await prefs;
    return p.getString(_keyOutletName);
  }

  Future<String?> getOutletCode() async {
    final p = await prefs;
    return p.getString(_keyOutletCode);
  }

  Future<String?> getDeviceId() async {
    final p = await prefs;
    return p.getString(_keyDeviceId);
  }

  Future<String?> getDeviceName() async {
    final p = await prefs;
    return p.getString(_keyDeviceName);
  }

  Future<String?> getUserName() async {
    final p = await prefs;
    return p.getString(_keyUserName);
  }

  Future<String?> getUserEmail() async {
    final p = await prefs;
    return p.getString(_keyUserEmail);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> saveAdminSession(String token, UserInfo user) async {
    final p = await prefs;
    await p.setString(_keyToken, token);
    await p.setString(_keyUserId, user.id);
    await p.setString(_keyUserName, user.name);
    await p.setString(_keyUserEmail, user.email);
  }

  Future<void> saveDeviceSession(
      String token, OutletInfo? outlet, DeviceInfo? device, String deviceIdLocal) async {
    final p = await prefs;
    await p.setString(_keyToken, token);
    if (outlet != null) {
      await p.setInt(_keyOutletId, outlet.id);
      await p.setString(_keyOutletName, outlet.name);
      if (outlet.activationCode != null) {
        await p.setString(_keyOutletCode, outlet.activationCode!);
      }
    }
    await p.setString(_keyDeviceId, deviceIdLocal);
    if (device != null) {
      await p.setInt(_keyDeviceDbId, device.id);
      await p.setString(_keyDeviceName, device.deviceName);
    }
  }

  Future<void> clearSession() async {
    final p = await prefs;
    final savedDeviceId = p.getString(_keyDeviceId);
    await p.clear();
    if (savedDeviceId != null) {
      await p.setString(_keyDeviceId, savedDeviceId);
    }
  }
}
