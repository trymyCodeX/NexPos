import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static const String _base = AppConstants.baseUrl;

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? body['error'] ?? 'Error ${response.statusCode}';
    } catch (_) {
      return 'Error ${response.statusCode}';
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    try {
      final res = await http
          .post(Uri.parse('$_base$path'),
              headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw ApiException(_parseError(res), statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw ApiException(_parseError(res), statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    try {
      final res = await http
          .put(Uri.parse('$_base$path'),
              headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw ApiException(_parseError(res), statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body,
      {String? token}) async {
    try {
      final res = await http
          .patch(Uri.parse('$_base$path'),
              headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw ApiException(_parseError(res), statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  Future<void> delete(String path, {String? token}) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base$path'), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) return;
      throw ApiException(_parseError(res), statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }
}
