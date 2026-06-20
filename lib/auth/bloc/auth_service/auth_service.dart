import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen/model/auth_model.dart';

class AuthService {
  final String baseUrl = "https://meet-2zo9.onrender.com/api/auth";

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint("================================");
    debugPrint("TOKEN SAVED SUCCESSFULLY: $token");
    debugPrint("================================");
  }

  // REGISTER
  Future<dynamic> register(UserModel user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: jsonEncode(user.toRegisterJson()),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data.containsKey('token')) {
        await _saveToken(data['token']);
      }
      return data;
    } else {
      throw Exception(data['message'] ?? "Registration Failed");
    }
  }

  ///-----------------------LOGIN-------------------
  Future<dynamic> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (data.containsKey('token')) {
        await _saveToken(data['token']);
      }

      // ⭐ ADD THIS FIX
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_id', data['user']['_id']);
      await prefs.setString('user_name', data['user']['name']);

      print("USER SAVED: ${data['user']}");
      return data;
    }

    throw Exception(data['message'] ?? "Login failed");
  }
}