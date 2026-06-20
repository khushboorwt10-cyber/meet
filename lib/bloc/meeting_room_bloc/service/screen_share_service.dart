import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScreenShareService {

  static const String baseUrl =
      "https://meet-2zo9.onrender.com/api/meeting";

  /// START SCREEN SHARE
  Future<bool> startScreenShare(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse("$baseUrl/screen-share/start"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "roomId": roomId,
        }),
      );

      print("SCREEN SHARE START => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }

      return false;
    } catch (e) {
      print("START SCREEN SHARE ERROR => $e");
      return false;
    }
  }

  /// CHECK SCREEN SHARE STATUS
  Future<Map<String, dynamic>?> getScreenShareStatus(
      String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse("$baseUrl/screen-share/$roomId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("SCREEN SHARE STATUS => ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("GET SCREEN SHARE STATUS ERROR => $e");
      return null;
    }
  }

  /// STOP SCREEN SHARE
  Future<bool> stopScreenShare(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse("$baseUrl/screen-share/stop"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "roomId": roomId,
        }),
      );

      print("SCREEN SHARE STOP => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }

      return false;
    } catch (e) {
      print("STOP SCREEN SHARE ERROR => $e");
      return false;
    }
  }
}