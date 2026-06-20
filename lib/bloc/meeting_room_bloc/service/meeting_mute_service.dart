import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MeetingMuteService {
  static const String baseUrl =
      "https://meet-2zo9.onrender.com/api/meeting";

  static Future<bool> selfMute({
    required String roomId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/self-mute"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "roomId": roomId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Self Mute Error => $e");
      return false;
    }
  }

  static Future<bool> selfUnMute({
    required String roomId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/self-unmute"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "roomId": roomId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Self UnMute Error => $e");
      return false;
    }
  }

  static Future<bool> muteUser({
    required String roomId,
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mute-user"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "roomId": roomId,
          "userId": userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Mute User Error => $e");
      return false;
    }
  }

  static Future<bool> unMuteUser({
    required String roomId,
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/unmute-user"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "roomId": roomId,
          "userId": userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("UnMute User Error => $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMuteStatus({
    required String roomId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/mute-status/$roomId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("Get Mute Status Error => $e");
      return null;
    }
  }
}