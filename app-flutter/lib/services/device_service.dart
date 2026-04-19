import 'dart:async';
import '../utils/constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class DeviceService {
  final ApiService _api;
  final SessionService _session;
  Timer? _heartbeatTimer;

  DeviceService(String token, this._session) : _api = ApiService(token: token);

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.heartbeatIntervalSeconds),
      (_) => _sendHeartbeat(),
    );
    _sendHeartbeat();
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    try {
      final deviceId = await _session.getDeviceId();
      if (deviceId == null) return;
      await _api.post('${AppConstants.apiDevices}/heartbeat', {'deviceId': deviceId});
    } catch (_) {}
  }

  Future<void> forceLogout(String deviceId) async {
    await _api.post('${AppConstants.apiDevices}/force-logout', {'deviceId': deviceId, 'id': deviceId});
  }

  Future<void> updateDeviceName(String id, String name) async {
    await _api.put('${AppConstants.apiDevices}/$id', {'deviceName': name});
  }

  Future<void> deleteDevice(String id) async {
    await _api.delete('${AppConstants.apiDevices}/$id');
  }
}
