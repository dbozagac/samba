import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/user_model.dart';

/// Typed error for API failures with ProblemDetails support.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;

  ApiException(this.statusCode, this.message, [this.fieldErrors = const {}]);

  @override
  String toString() => message;
}

/// Paginated response from the API.
class PagedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });
}

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<PagedResponse<UserModel>> listUsers(
    String idToken, {
    int page = 1,
    int pageSize = 20,
    String? search,
    String sortBy = 'id',
    bool sortDesc = true,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortDesc': sortDesc.toString(),
    };
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/api/users').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers(idToken));

    _throwIfFailed(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>)
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PagedResponse(
      items: items,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Future<void> createUser(String idToken, {
    required String username,
    required String tcNo,
    required String email,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: _headers(idToken),
      body: jsonEncode({
        'username': username,
        'tcNo': tcNo,
        'email': email,
        'phone': phone,
      }),
    );

    _throwIfFailed(response);
  }

  Future<void> updateUser(String idToken, int id, {
    required String username,
    required String tcNo,
    required String email,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: _headers(idToken),
      body: jsonEncode({
        'username': username,
        'tcNo': tcNo,
        'email': email,
        'phone': phone,
      }),
    );

    _throwIfFailed(response);
  }

  Future<void> deleteUser(String idToken, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: _headers(idToken),
    );

    _throwIfFailed(response);
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Parses RFC 7807 ProblemDetails or falls back to raw body.
  void _throwIfFailed(http.Response response) {
    if (response.statusCode < 400) return;

    String message = 'API isteği başarısız oldu.';
    Map<String, String> fieldErrors = {};

    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          // ProblemDetails → detail field
          message = (json['detail'] as String?) ??
              (json['message'] as String?) ??
              (json['title'] as String?) ??
              message;

          // Extract field-level errors
          final errors = json['errors'];
          if (errors is Map<String, dynamic>) {
            for (final entry in errors.entries) {
              final value = entry.value;
              if (value is List && value.isNotEmpty) {
                fieldErrors[entry.key] = value.first.toString();
              } else if (value is String) {
                fieldErrors[entry.key] = value;
              }
            }
          }
        } else {
          message = response.body;
        }
      } catch (_) {
        message = response.body;
      }
    }

    throw ApiException(response.statusCode, message, fieldErrors);
  }
}
