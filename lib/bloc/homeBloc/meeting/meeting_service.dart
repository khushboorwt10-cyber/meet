import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MeetingHistoryService {
  static const String baseUrl =
      "http://192.168.1.2:5000/api/meeting";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  Future<List<dynamic>> getMeetingHistory() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/history"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("HISTORY STATUS => ${response.statusCode}");
    print("HISTORY RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["meetings"] ?? [];
    }

    throw Exception(data["message"] ?? "Failed");
  }
}