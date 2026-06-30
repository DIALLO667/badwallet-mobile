import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class HttpClient {
  static const _timeout = Duration(seconds: 30);

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Impossible de se connecter au serveur');
    } on TimeoutException {
      throw const ApiException('La connexion a expiré');
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Impossible de se connecter au serveur');
    } on TimeoutException {
      throw const ApiException('La connexion a expiré');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    final message = body['message'] ?? 'Une erreur est survenue';
    throw ApiException(message.toString(), statusCode: response.statusCode);
  }
}
