import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  static const Duration _timeout = Duration(seconds: 30);

  final String? _token;

  ApiService({String? token}) : _token = token;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    final body = response.body;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ?? 'Terjadi kesalahan';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final response = await http
          .get(_uri(path, queryParams), headers: _headers)
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Tidak bisa menjangkau server. Periksa koneksi internet.');
    } on HttpException {
      throw ApiException('Koneksi terputus. Coba lagi.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Coba lagi.');
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Tidak bisa menjangkau server. Periksa koneksi internet.');
    } on HttpException {
      throw ApiException('Koneksi terputus. Coba lagi.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Coba lagi.');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Tidak bisa menjangkau server. Periksa koneksi internet.');
    } on HttpException {
      throw ApiException('Koneksi terputus. Coba lagi.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Coba lagi.');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http
          .delete(_uri(path), headers: _headers)
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Tidak bisa menjangkau server. Periksa koneksi internet.');
    } on HttpException {
      throw ApiException('Koneksi terputus. Coba lagi.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Coba lagi.');
    }
  }
}
