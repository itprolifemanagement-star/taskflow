import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API client for the TaskFlow PHP backend.
/// Keep the backend URL here so it can be changed without touching screens.
class ApiService {
  static const String baseUrl = 'https://evaluation.pwestora.com/taskflow_api';
  static const Duration requestTimeout = Duration(seconds: 20);

  static String? _cachedToken;

  static Future<String?> get _token async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('$baseUrl/$endpoint');
    if (query != null) uri = uri.replace(queryParameters: query);

    try {
      final res = await http.get(uri, headers: await _headers()).timeout(requestTimeout);
      return _decode(res);
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to connect to the server.'};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');

    try {
      final res = await http
          .post(uri, headers: await _headers(), body: jsonEncode(body))
          .timeout(requestTimeout);
      return _decode(res);
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to connect to the server.'};
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');

    try {
      final request = http.MultipartRequest('POST', uri);
      final token = await _token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      if (fields != null) request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send().timeout(requestTimeout);
      final res = await http.Response.fromStream(streamed);
      return _decode(res);
    } on TimeoutException {
      return {'success': false, 'message': 'Upload timed out. Please try again.'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to upload the file.'};
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          return {
            ...decoded,
            'success': false,
            'message': decoded['message'] ?? 'Server returned ${res.statusCode}.',
          };
        }
        return decoded;
      }
      return {'success': false, 'message': 'Unexpected response format.'};
    } catch (_) {
      return {
        'success': false,
        'message': res.statusCode >= 500
            ? 'Server error. Please try again later.'
            : 'Unexpected server response (${res.statusCode}).',
      };
    }
  }
}
