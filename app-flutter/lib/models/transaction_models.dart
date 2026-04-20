class TransactionInfo {
    final String id;
    final int outletId;
    final String customer;
    final String? service;
    final double amount;
    final String status;
    final String createdAt;
    final String? updatedAt;
    final String? outletName;
    final String? customerId;
    final String? serviceId;
    // BUG FIX: quantity bertipe double agar mendukung layanan berbasis berat (mis. 2.5 kg)
    // Sebelumnya int sehingga nilai desimal dari server akan dipotong
    final double? quantity;

    TransactionInfo({
      required this.id,
      required this.outletId,
      required this.customer,
      this.service,
      required this.amount,
      required this.status,
      required this.createdAt,
      this.updatedAt,
      this.outletName,
      this.customerId,
      this.serviceId,
      this.quantity,
    });

    factory TransactionInfo.fromJson(Map<String, dynamic> json) {
      return TransactionInfo(
        id: json['id']?.toString() ?? '0',
        outletId: _parseInt(json['outletId']),
        customer: json['customer'] ?? json['customerName'] ?? '',
        service: json['service'] ?? json['serviceName'],
        amount: _parseDouble(json['amount'] ?? json['totalAmount']),
        status: json['status'] ?? 'diterima',
        createdAt: json['createdAt'] ?? '',
        updatedAt: json['updatedAt'],
        outletName: json['outletName'],
        customerId: json['customerId']?.toString(),
        serviceId: json['serviceId']?.toString(),
        // BUG FIX: parse sebagai double agar presisi desimal tidak hilang
        quantity: json['quantity'] != null ? _parseDouble(json['quantity']) : null,
      );
    }
  }

  // BUG FIX: quantity bertipe double agar mendukung layanan berbasis berat (mis. 2.5 kg)
  class CreateTransactionRequest {
    final int outletId;
    final String customerId;
    final String serviceId;
    final double quantity;

    CreateTransactionRequest({
      required this.outletId,
      required this.customerId,
      required this.serviceId,
      required this.quantity,
    });

    Map<String, dynamic> toJson() => {
          'outletId': outletId,
          'customerId': customerId,
          'serviceId': serviceId,
          'quantity': quantity,
        };
  }

  class UpdateStatusRequest {
    final String transactionId;
    final String status;

    UpdateStatusRequest({required this.transactionId, required this.status});

    Map<String, dynamic> toJson() => {'transactionId': transactionId, 'status': status};
  }

  class ServiceInfo {
    final String id;
    final String name;
    final int price;
    final String unit;
    final String? outletId;
    final double? minQuantity;

    ServiceInfo({required this.id, required this.name, required this.price, required this.unit, this.outletId, this.minQuantity});

    factory ServiceInfo.fromJson(Map<String, dynamic> json) => ServiceInfo(
          id: json['id']?.toString() ?? '',
          name: json['name'] ?? '',
          price: _parseInt(json['price']),
          unit: json['unit'] ?? 'kg',
          outletId: json['outlet_id']?.toString(),
          minQuantity: json['min_quantity'] != null ? _parseDouble(json['min_quantity']) : null,
        );
  }

  class CustomerInfo {
    final String id;
    final String name;
    final String phone;
    final String address;
    final String? outletId;

    CustomerInfo({required this.id, required this.name, required this.phone, required this.address, this.outletId});

    factory CustomerInfo.fromJson(Map<String, dynamic> json) => CustomerInfo(
          id: json['id']?.toString() ?? '',
          name: json['name'] ?? '',
          phone: json['phone'] ?? '',
          address: json['address'] ?? '',
          outletId: json['outlet_id']?.toString(),
        );
  }

  class ReportSummary {
    final int totalTransactions;
    final double totalIncome;
    final int totalDiterima;
    final int totalDicuci;
    final int totalDisetrika;
    final int totalSelesai;
    final int totalDibatalkan;

    ReportSummary({
      required this.totalTransactions,
      required this.totalIncome,
      required this.totalDiterima,
      required this.totalDicuci,
      required this.totalDisetrika,
      required this.totalSelesai,
      required this.totalDibatalkan,
    });

    factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
          totalTransactions: _parseInt(json['totalTransactions']),
          totalIncome: _parseDouble(json['totalIncome']),
          totalDiterima: _parseInt(json['totalDiterima']),
          totalDicuci: _parseInt(json['totalDicuci']),
          totalDisetrika: _parseInt(json['totalDisetrika']),
          totalSelesai: _parseInt(json['totalSelesai']),
          totalDibatalkan: _parseInt(json['totalDibatalkan']),
        );
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  