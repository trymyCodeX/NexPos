// ─── Auth ───────────────────────────────────────────────
  class LoginRequest {
    final String email;
    final String password;
    LoginRequest({required this.email, required this.password});
    Map<String, dynamic> toJson() => {'email': email, 'password': password};
  }

  class RegisterRequest {
    final String name;
    final String email;
    final String password;
    RegisterRequest({required this.name, required this.email, required this.password});
    Map<String, dynamic> toJson() => {'name': name, 'email': email, 'password': password};
  }

  class UserInfo {
    final String id;
    final String name;
    final String email;
    final String? accountStatus;
    UserInfo({required this.id, required this.name, required this.email, this.accountStatus});
    factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
          id: j['id']?.toString() ?? '',
          name: j['name'] ?? '',
          email: j['email'] ?? '',
          accountStatus: j['accountStatus'],
        );
  }

  class LoginResponse {
    final String token;
    final UserInfo user;
    LoginResponse({required this.token, required this.user});
    factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
          token: j['token'] ?? '',
          user: UserInfo.fromJson(j['user'] ?? {}),
        );
  }

  // ─── Outlet ─────────────────────────────────────────────
  class OutletInfo {
    final int id;
    final String name;
    final String activationCode;
    final int? deviceCount;
    final int? transactionCount;
    final String? createdAt;
    OutletInfo({
      required this.id,
      required this.name,
      required this.activationCode,
      this.deviceCount,
      this.transactionCount,
      this.createdAt,
    });
    factory OutletInfo.fromJson(Map<String, dynamic> j) => OutletInfo(
          id: j['id'] ?? 0,
          name: j['name'] ?? '',
          activationCode: j['activationCode'] ?? j['activation_code'] ?? '',
          deviceCount: j['deviceCount'] ?? j['device_count'],
          transactionCount: j['transactionCount'] ?? j['transaction_count'],
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }

  // ─── Device ─────────────────────────────────────────────
  class DeviceInfo {
    final int id;
    final String deviceId;
    final String deviceName;
    final String outletName;
    final int outletId;
    // BUG FIX: server mengirim field 'status' (string 'online'/'offline'), bukan 'isActive' (bool)
    final bool isActive;
    final String? lastSeen;
    DeviceInfo({
      required this.id,
      required this.deviceId,
      required this.deviceName,
      required this.outletName,
      required this.outletId,
      required this.isActive,
      this.lastSeen,
    });
    factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
          id: j['id'] ?? 0,
          deviceId: j['deviceId'] ?? j['device_id'] ?? '',
          deviceName: j['deviceName'] ?? j['device_name'] ?? '',
          outletName: j['outletName'] ?? j['outlet_name'] ?? '',
          outletId: j['outletId'] ?? j['outlet_id'] ?? 0,
          // BUG FIX: derive isActive dari field 'status' yang dikirim server
          isActive: (j['status'] ?? j['isActive'] ?? j['is_active'] ?? '').toString().toLowerCase() == 'online'
              || j['isActive'] == true || j['is_active'] == true,
          lastSeen: j['lastSeen'] ?? j['last_seen'],
        );
  }

  // ─── Transaction ────────────────────────────────────────
  class TransactionInfo {
    final int id;
    final String customerName;
    final String outletName;
    // BUG FIX: server mengirim 'totalAmount', bukan 'totalPrice'
    final num totalPrice;
    final String status;
    final String? createdAt;
    TransactionInfo({
      required this.id,
      required this.customerName,
      required this.outletName,
      required this.totalPrice,
      required this.status,
      this.createdAt,
    });
    factory TransactionInfo.fromJson(Map<String, dynamic> j) => TransactionInfo(
          id: j['id'] ?? 0,
          customerName: j['customerName'] ?? j['customer_name'] ?? j['customer'] ?? '',
          outletName: j['outletName'] ?? j['outlet_name'] ?? '',
          // BUG FIX: baca dari 'totalAmount' atau 'amount' jika 'totalPrice' tidak ada
          totalPrice: j['totalPrice'] ?? j['total_price'] ?? j['totalAmount'] ?? j['total_amount'] ?? j['amount'] ?? 0,
          status: j['status'] ?? '',
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }

  // ─── Report ─────────────────────────────────────────────
  // BUG FIX: server mengirim totalIncome (bukan totalRevenue), dan status per jenis
  // bukan totalCustomers/pendingCount/completedCount/outletReports
  class ReportSummary {
    final int totalTransactions;
    // Disimpan sebagai totalRevenue agar layar lama tidak perlu diubah
    final num totalRevenue;
    // totalCustomers tidak tersedia dari server /api/reports/summary
    final int totalCustomers;
    // pendingCount = diterima + dicuci + disetrika
    final int pendingCount;
    // completedCount = selesai
    final int completedCount;
    // outletReports tidak tersedia dari endpoint summary
    final List<OutletReport> outletReports;

    ReportSummary({
      required this.totalTransactions,
      required this.totalRevenue,
      required this.totalCustomers,
      required this.pendingCount,
      required this.completedCount,
      required this.outletReports,
    });

    factory ReportSummary.fromJson(Map<String, dynamic> j) {
      final diterima = j['totalDiterima'] ?? j['total_diterima'] ?? 0;
      final dicuci = j['totalDicuci'] ?? j['total_dicuci'] ?? 0;
      final disetrika = j['totalDisetrika'] ?? j['total_disetrika'] ?? 0;
      final selesai = j['totalSelesai'] ?? j['total_selesai'] ?? 0;

      return ReportSummary(
        totalTransactions: j['totalTransactions'] ?? j['total_transactions'] ?? 0,
        // BUG FIX: server kirim 'totalIncome', bukan 'totalRevenue'
        totalRevenue: j['totalRevenue'] ?? j['total_revenue'] ?? j['totalIncome'] ?? j['total_income'] ?? 0,
        // server tidak menyediakan totalCustomers di endpoint ini
        totalCustomers: j['totalCustomers'] ?? j['total_customers'] ?? 0,
        // BUG FIX: hitung pending dari penjumlahan status yang belum selesai
        pendingCount: (diterima is num ? diterima.toInt() : 0) +
            (dicuci is num ? dicuci.toInt() : 0) +
            (disetrika is num ? disetrika.toInt() : 0),
        // BUG FIX: completedCount dari totalSelesai
        completedCount: selesai is num ? selesai.toInt() : 0,
        // outletReports tidak tersedia dari summary endpoint
        outletReports: (j['outletReports'] ?? j['outlet_reports'] ?? [])
            .map<OutletReport>((e) => OutletReport.fromJson(e))
            .toList(),
      );
    }
  }

  class OutletReport {
    final String outletName;
    final int transactionCount;
    final num revenue;
    OutletReport({required this.outletName, required this.transactionCount, required this.revenue});
    factory OutletReport.fromJson(Map<String, dynamic> j) => OutletReport(
          outletName: j['outletName'] ?? j['outlet_name'] ?? '',
          transactionCount: j['transactionCount'] ?? j['transaction_count'] ?? 0,
          revenue: j['revenue'] ?? 0,
        );
  }

  // ─── Notification ───────────────────────────────────────
  class NotificationInfo {
    final int id;
    final String title;
    final String message;
    final String type;
    final bool isRead;
    final String? createdAt;
    NotificationInfo({
      required this.id,
      required this.title,
      required this.message,
      required this.type,
      required this.isRead,
      this.createdAt,
    });
    factory NotificationInfo.fromJson(Map<String, dynamic> j) => NotificationInfo(
          id: j['id'] ?? 0,
          title: j['title'] ?? '',
          message: j['message'] ?? '',
          type: j['type'] ?? 'info',
          isRead: j['isRead'] ?? j['is_read'] ?? false,
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }

  // ─── SuperAdmin ─────────────────────────────────────────
  class SuperAdminUser {
    final String id;
    final String email;
    final String name;
    final String accountStatus;
    final String? penaltyReason;
    final bool bannedPermanent;
    final int outletCount;
    final int deviceCount;
    final String? createdAt;
    SuperAdminUser({
      required this.id,
      required this.email,
      required this.name,
      required this.accountStatus,
      this.penaltyReason,
      required this.bannedPermanent,
      required this.outletCount,
      required this.deviceCount,
      this.createdAt,
    });
    factory SuperAdminUser.fromJson(Map<String, dynamic> j) => SuperAdminUser(
          id: j['id']?.toString() ?? '',
          email: j['email'] ?? '',
          name: j['name'] ?? '',
          accountStatus: j['accountStatus'] ?? j['account_status'] ?? 'active',
          penaltyReason: j['penaltyReason'] ?? j['penalty_reason'],
          bannedPermanent: j['bannedPermanent'] ?? j['banned_permanent'] ?? false,
          outletCount: j['outletCount'] ?? j['outlet_count'] ?? 0,
          deviceCount: j['deviceCount'] ?? j['device_count'] ?? 0,
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }

  class SuperAdminStats {
    final int totalUsers;
    final int totalOutlets;
    final int totalDevices;
    final int totalTransactions;
    final int totalOtpRequests;
    SuperAdminStats({
      required this.totalUsers,
      required this.totalOutlets,
      required this.totalDevices,
      required this.totalTransactions,
      required this.totalOtpRequests,
    });
    factory SuperAdminStats.fromJson(Map<String, dynamic> j) => SuperAdminStats(
          totalUsers: j['totalUsers'] ?? 0,
          totalOutlets: j['totalOutlets'] ?? 0,
          totalDevices: j['totalDevices'] ?? 0,
          totalTransactions: j['totalTransactions'] ?? 0,
          totalOtpRequests: j['totalOtpRequests'] ?? 0,
        );
  }

  class OtpRequestInfo {
    final int id;
    final String email;
    final String? name;
    final String otpCode;
    final String? message;
    final String? createdAt;
    OtpRequestInfo({
      required this.id,
      required this.email,
      this.name,
      required this.otpCode,
      this.message,
      this.createdAt,
    });
    factory OtpRequestInfo.fromJson(Map<String, dynamic> j) => OtpRequestInfo(
          id: j['id'] ?? 0,
          email: j['email'] ?? '',
          name: j['name'],
          otpCode: j['otpCode'] ?? j['otp_code'] ?? '',
          message: j['message'],
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }

  // ─── Transaction Log ─────────────────────────────────────
  class TransactionLogInfo {
    final int id;
    final int? transactionId;
    final String action;
    final String? outletName;
    final String? customerName;
    final String? serviceName;
    final num? quantity;
    final num? totalAmount;
    final String? status;
    final String? actorType;
    final String? notes;
    final String? createdAt;

    TransactionLogInfo({
      required this.id,
      this.transactionId,
      required this.action,
      this.outletName,
      this.customerName,
      this.serviceName,
      this.quantity,
      this.totalAmount,
      this.status,
      this.actorType,
      this.notes,
      this.createdAt,
    });

    factory TransactionLogInfo.fromJson(Map<String, dynamic> j) => TransactionLogInfo(
          id: j['id'] ?? 0,
          transactionId: j['transactionId'] ?? j['transaction_id'],
          action: j['action'] ?? '',
          outletName: j['outletName'] ?? j['outlet_name'],
          customerName: j['customerName'] ?? j['customer_name'],
          serviceName: j['serviceName'] ?? j['service_name'],
          quantity: j['quantity'],
          totalAmount: j['totalAmount'] ?? j['total_amount'],
          status: j['status'],
          actorType: j['actorType'] ?? j['actor_type'],
          notes: j['notes'],
          createdAt: j['createdAt'] ?? j['created_at'],
        );
  }
  