import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show VoidCallback, compute;
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/errors.dart';
import 'circuit_breaker.dart';

class ApiClient {
  static const _isolateJsonThreshold = 64 * 1024;

  ApiClient({
    required http.Client httpClient,
    required this._readToken,
    CircuitBreaker? breaker,
    this.baseUrl = ApiConfig.baseUrl,
    this.timeout = ApiConfig.timeout,
  }) : _http = httpClient,
       breaker = breaker ?? CircuitBreaker(isFailure: isNetworkFailure);

  final String baseUrl;
  final Duration timeout;
  final CircuitBreaker breaker;
  final http.Client _http;
  final String? Function() _readToken;

  VoidCallback? onUnauthorized;

  static bool isNetworkFailure(Object error) =>
      error is NetworkException ||
      (error is ApiException && error.statusCode >= 500);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) {
    return breaker.run(() async {
      final token = _readToken();
      final uri = Uri.parse(
        '$baseUrl${ApiConfig.prefix}$path',
      ).replace(queryParameters: query == null || query.isEmpty ? null : query);
      final request = http.Request(method, uri)
        ..headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final response = await _execute(request);
      final status = response.statusCode;
      if (status == 401 && token != null) onUnauthorized?.call();
      if (status >= 400) throw ApiException(status, _errorOf(response));
      if (response.body.isEmpty) return null;
      final parsed = response.body.length >= _isolateJsonThreshold
          ? await compute(_decodeJson, response.body, debugLabel: 'api-json')
          : _decodeJson(response.body);
      if (!parsed.valid) throw const NetworkException('bad_response');
      return parsed.value;
    });
  }

  static ({bool valid, Object? value}) _decodeJson(String body) {
    try {
      return (valid: true, value: jsonDecode(body));
    } on FormatException {
      return (valid: false, value: null);
    }
  }

  Future<http.Response> _execute(http.Request request) async {
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException('timeout');
    } on IOException catch (e) {
      throw NetworkException(e.runtimeType.toString());
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
  }

  static String _errorOf(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      final error = json is Map ? json['error'] : null;
      if (error is String) return error;
    } on FormatException {
      return 'HTTP ${response.statusCode}';
    }
    return 'HTTP ${response.statusCode}';
  }
}
