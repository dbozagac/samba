import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<List<UserModel>> listUsers(String idToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: _headers(idToken),
    );

    _throwIfFailed(response);

    final parsed = jsonDecode(response.body) as List<dynamic>;
    return parsed
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
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

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception(response.body.isNotEmpty ? response.body : 'API request failed');
    }
  }
}
