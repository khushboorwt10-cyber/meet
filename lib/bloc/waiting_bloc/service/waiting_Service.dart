import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class WaitingService {
  final String baseUrl = "https://meet-five-ruby.vercel.app/api/meeting/waiting/";

  Future<String> checkWaitingStatus(
      String roomId,
      String participantId,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final url = "$baseUrl$roomId";

      debugPrint("--- CHECKING STATUS ---");
      debugPrint("URL: $url");
      debugPrint("Looking for ParticipantId: $participantId");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List participants = data['participants'] ?? [];

        debugPrint(
          "Participants list size: ${participants.length}",
        );

        // Debug print for all participants
        for (var p in participants) {
          debugPrint(
            "ParticipantID => ${p['_id']} | "
                "UserID => ${p['userId']?['_id']} | "
                "Status => ${p['status']}",
          );
        }

        var myParticipant =
        participants.cast<Map<String, dynamic>?>().firstWhere(
              (p) =>
          p != null &&
              p['_id'] == participantId,
          orElse: () => null,
        );

        if (myParticipant != null) {
          debugPrint(
            "✅ Match Found! Status: ${myParticipant['status']}",
          );

          return myParticipant['status'];
        }

        debugPrint(
          "🔥 Participant removed from waiting list -> APPROVED",
        );

        return 'approved';
      } else {
        debugPrint(
          "❌ API Error. Status Code: ${response.statusCode}",
        );
      }

      return 'waiting';
    } catch (e) {
      debugPrint(
        "🚨 Exception in WaitingService: $e",
      );
      return 'error';
    }
  }
}