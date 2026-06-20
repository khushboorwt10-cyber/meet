import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // debugPrint ke liye
import '../model/join_meet_model.dart';

class ApiService {
  final String baseUrl = "https://meet-2zo9.onrender.com/api/meeting/join";

  Future<JoinMeetingResponse> joinMeeting(String roomId, String token) async {

    debugPrint("--- API CALL START ---");
    debugPrint("URL: $baseUrl");
    debugPrint("RoomID: $roomId");
    debugPrint("Token: $token");

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "roomId": roomId,
        }),
      );

      debugPrint("--- API CALL END ---");
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return JoinMeetingResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception("Failed to join: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error occurred: ${e.toString()}");
      throw Exception("Error occurred: ${e.toString()}");
    }
  }
}