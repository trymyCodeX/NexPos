import '../models/transaction_models.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class TransactionService {
  final ApiService _api;

  TransactionService(String token) : _api = ApiService(token: token);

  Future<List<TransactionInfo>> getTransactions({int? outletId}) async {
    final queryParams = outletId != null ? {'outletId': outletId.toString()} : null;
    final data = await _api.get(AppConstants.apiTransactions, queryParams: queryParams);
    final list = data['transactions'] as List? ?? [];
    return list.map((e) => TransactionInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TransactionInfo> createTransaction(CreateTransactionRequest request) async {
    final data = await _api.post(AppConstants.apiTransactions, request.toJson());
    return TransactionInfo.fromJson(data);
  }

  Future<TransactionInfo> updateStatus(int transactionId, String status) async {
    final data = await _api.put('${AppConstants.apiTransactions}/status', {
      'transactionId': transactionId,
      'status': status,
    });
    return TransactionInfo.fromJson(data);
  }

  Future<void> deleteTransaction(int id) async {
    await _api.delete('${AppConstants.apiTransactions}/$id');
  }

  Future<List<ServiceInfo>> getServices(int outletId) async {
    final data = await _api.get(AppConstants.apiServices, queryParams: {'outletId': outletId.toString()});
    final list = data['services'] as List? ?? [];
    return list.map((e) => ServiceInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceInfo> createService(int outletId, String name, int price, String unit) async {
    final data = await _api.post(AppConstants.apiServices, {
      'outletId': outletId,
      'name': name,
      'price': price,
      'unit': unit,
    });
    return ServiceInfo.fromJson(data['service'] as Map<String, dynamic>);
  }

  Future<ServiceInfo> updateService(String id, String name, int price, String unit) async {
    final data = await _api.put('${AppConstants.apiServices}/$id', {
      'name': name,
      'price': price,
      'unit': unit,
    });
    return ServiceInfo.fromJson(data['service'] as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _api.delete('${AppConstants.apiServices}/$id');
  }

  Future<List<CustomerInfo>> getCustomers(int outletId) async {
    final data = await _api.get(AppConstants.apiCustomers, queryParams: {'outletId': outletId.toString()});
    final list = data['customers'] as List? ?? [];
    return list.map((e) => CustomerInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerInfo> createCustomer(int outletId, String name, String phone, String address) async {
    final data = await _api.post(AppConstants.apiCustomers, {
      'outletId': outletId,
      'name': name,
      'phone': phone,
      'address': address,
    });
    return CustomerInfo.fromJson(data['customer'] as Map<String, dynamic>);
  }

  Future<CustomerInfo> updateCustomer(String id, String name, String phone, String address) async {
    final data = await _api.put('${AppConstants.apiCustomers}/$id', {
      'name': name,
      'phone': phone,
      'address': address,
    });
    return CustomerInfo.fromJson(data['customer'] as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(String id) async {
    await _api.delete('${AppConstants.apiCustomers}/$id');
  }

  Future<ReportSummary> getReportSummary({int? outletId}) async {
    final queryParams = outletId != null ? {'outletId': outletId.toString()} : null;
    final data = await _api.get('${AppConstants.apiReports}/summary', queryParams: queryParams);
    return ReportSummary.fromJson(data);
  }
}
