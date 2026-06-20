import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostService {
  final String baseUrl = "https://meet-2zo9.onrender.com/api/meeting";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ADMIT USER
  Future<bool> admitUser(String roomId, String userId) async {
    String? token = await _getToken();
    debugPrint("Admitting User: $userId, Token: $token");

    final response = await http.post(
      Uri.parse('$baseUrl/admit-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'roomId': roomId, 'userId': userId}),
    );

    debugPrint("Admit Response Status: ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<List<dynamic>> getWaitingParticipants(String roomId) async {
    String? token = await _getToken();
    final url = "https://meet-2zo9.onrender.com/api/meeting/participants/$roomId";

    debugPrint("Fetching participants from: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Participants Fetch Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['participants'] ?? [];
      } else {
        debugPrint("Error Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching participants: $e");
    }
    return [];
  }

  // REJECT USER
  Future<bool> rejectUser(String roomId, String userId) async {
    String? token = await _getToken();
    debugPrint("Rejecting User: $userId");

    final response = await http.post(
      Uri.parse('$baseUrl/reject-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'roomId': roomId, 'userId': userId}),
    );

    debugPrint("Reject Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}