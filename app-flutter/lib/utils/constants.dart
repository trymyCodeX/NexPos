class AppConstants {
  static const String baseUrl = 'https://nexpos-production-3747.up.railway.app';

  static const String apiAuth = '/api/auth';
  static const String apiOutlets = '/api/outlets';
  static const String apiDevices = '/api/devices';
  static const String apiTransactions = '/api/transactions';
  static const String apiServices = '/api/services';
  static const String apiCustomers = '/api/customers';
  static const String apiNotifications = '/api/notifications';
  static const String apiReports = '/api/reports';
  static const String apiSuperAdmin = '/api/super-admin';

  static const List<String> validStatuses = [
    'diterima',
    'dicuci',
    'disetrika',
    'selesai',
    'dibatalkan',
  ];

  static const Map<String, String> statusLabels = {
    'diterima': 'Diterima',
    'dicuci': 'Dicuci',
    'disetrika': 'Disetrika',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
  };

  static const int heartbeatIntervalSeconds = 30;
  static const int heartbeatTimeoutDays = 2;
}
