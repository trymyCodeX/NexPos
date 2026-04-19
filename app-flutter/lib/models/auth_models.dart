class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({required this.email, required this.password, required this.name});

  Map<String, dynamic> toJson() => {'email': email, 'password': password, 'name': name};
}

class DeviceLoginRequest {
  final String activationCode;
  final String deviceName;
  final String deviceId;

  DeviceLoginRequest({required this.activationCode, required this.deviceName, required this.deviceId});

  Map<String, dynamic> toJson() => {
        'activationCode': activationCode,
        'deviceName': deviceName,
        'deviceId': deviceId,
      };
}

class UserInfo {
  final String id;
  final String email;
  final String name;

  UserInfo({required this.id, required this.email, required this.name});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id']?.toString() ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
      );
}

class OutletInfo {
  final int id;
  final String name;
  final String ownerId;
  final String? activationCode;

  OutletInfo({required this.id, required this.name, required this.ownerId, this.activationCode});

  factory OutletInfo.fromJson(Map<String, dynamic> json) => OutletInfo(
        id: _parseInt(json['id']),
        name: json['name'] ?? '',
        ownerId: json['ownerId']?.toString() ?? '',
        activationCode: json['activationCode'],
      );
}

class DeviceInfo {
  final int id;
  final String deviceName;
  final String deviceId;
  final String status;
  final int outletId;
  final String? lastSeen;
  final String? outletName;

  DeviceInfo({
    required this.id,
    required this.deviceName,
    required this.deviceId,
    required this.status,
    required this.outletId,
    this.lastSeen,
    this.outletName,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        id: _parseInt(json['id']),
        deviceName: json['deviceName'] ?? '',
        deviceId: json['deviceId'] ?? '',
        status: json['status'] ?? 'offline',
        outletId: _parseInt(json['outletId']),
        lastSeen: json['lastSeen'],
        outletName: json['outletName'],
      );
}

class AuthResponse {
  final String token;
  final UserInfo? user;
  final OutletInfo? outlet;
  final DeviceInfo? device;

  AuthResponse({required this.token, this.user, this.outlet, this.device});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] ?? '',
        user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
        outlet: json['outlet'] != null ? OutletInfo.fromJson(json['outlet']) : null,
        device: json['device'] != null ? DeviceInfo.fromJson(json['device']) : null,
      );
}

class ForgotPasswordRequest {
  final String email;
  ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyOtpRequest {
  final String email;
  final String otp;
  VerifyOtpRequest({required this.email, required this.otp});
  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class ResetPasswordRequest {
  final String email;
  final String resetToken;
  final String newPassword;
  ResetPasswordRequest({required this.email, required this.resetToken, required this.newPassword});
  Map<String, dynamic> toJson() => {'email': email, 'resetToken': resetToken, 'newPassword': newPassword};
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  ChangePasswordRequest({required this.currentPassword, required this.newPassword});
  Map<String, dynamic> toJson() => {'currentPassword': currentPassword, 'newPassword': newPassword};
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
