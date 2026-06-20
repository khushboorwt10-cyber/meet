import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService {
  static const String baseUrl =
      "http://192.168.1.2:5000/api/scheduled-meeting";

  Future<String?> _getToken() async {
    print("🔐 ========== GETTING TOKEN ==========");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      print("✅ TOKEN FOUND: ${token != null ? 'Yes (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'No'}");
      print("🔐 ===================================");
      return token;
    } catch (e) {
      print("❌ ERROR GETTING TOKEN: $e");
      print("🔐 ===================================");
      return null;
    }
  }

  // GET ALL SCHEDULES - Updated to use /upcoming endpoint
  Future<List<dynamic>> getSchedules() async {
    print("📋 ========== GET SCHEDULES ==========");
    print("⏰ TIME: ${DateTime.now()}");
    
    try {
      final token = await _getToken();
      // Changed from my-scheduled to upcoming
      final url = "$baseUrl/upcoming";
      
      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");
      print("📤 HEADERS: {Content-Type: application/json, Authorization: Bearer ***}");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Handle the new response structure
        final meetings = data["meetings"] ?? [];
        print("✅ SUCCESS: Found ${meetings.length} meetings");
        print("📋 ===================================");
        return meetings;
      } else {
        print("❌ ERROR: ${data["message"] ?? "Failed to fetch schedules"}");
        print("📋 ===================================");
        throw Exception(
          data["message"] ?? "Failed to fetch schedules",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("📋 ===================================");
      rethrow;
    }
  }

  // CREATE NEW SCHEDULE
  Future<Map<String, dynamic>> createSchedule({
    required String topic,
    required String description,
    required DateTime scheduledDate,
  }) async {
    print("➕ ========== CREATE SCHEDULE ==========");
    print("⏰ TIME: ${DateTime.now()}");
    print("📝 TOPIC: $topic");
    print("📝 DESCRIPTION: $description");
    print("📅 SCHEDULED DATE: ${scheduledDate.toIso8601String()}");
    
    try {
      final token = await _getToken();
      final url = "$baseUrl/schedule";
      
      final body = {
        "topic": topic,
        "description": description,
        "scheduledDate": scheduledDate.toIso8601String(),
        "duration": 30,
        "waitingRoom": true,
      };

      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");
      print("📤 REQUEST BODY: ${jsonEncode(body)}");
      print("📤 HEADERS: {Content-Type: application/json, Authorization: Bearer ***}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCESS: Meeting created successfully");
        print("🆔 ROOM ID: ${data['roomId'] ?? 'N/A'}");
        print("➕ ===================================");
        return data;
      } else {
        print("❌ ERROR: ${data["message"] ?? "Failed to create schedule"}");
        print("➕ ===================================");
        throw Exception(
          data["message"] ?? "Failed to create schedule",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("➕ ===================================");
      rethrow;
    }
  }

  // UPDATE SCHEDULE using roomId
  Future<Map<String, dynamic>> updateSchedule({
    required String roomId,
    required String topic,
    required String description,
    required DateTime scheduledDate,
  }) async {
    print("✏️ ========== UPDATE SCHEDULE ==========");
    print("⏰ TIME: ${DateTime.now()}");
    print("🆔 ROOM ID: $roomId");
    print("📝 TOPIC: $topic");
    print("📝 DESCRIPTION: $description");
    print("📅 SCHEDULED DATE: ${scheduledDate.toIso8601String()}");
    
    try {
      final token = await _getToken();
      final url = "$baseUrl/$roomId";
      
      final body = {
        "topic": topic,
        "description": description,
        "scheduledDate": scheduledDate.toIso8601String(),
      };

      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");
      print("📤 REQUEST BODY: ${jsonEncode(body)}");
      print("📤 HEADERS: {Content-Type: application/json, Authorization: Bearer ***}");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ SUCCESS: Meeting updated successfully");
        print("✏️ ===================================");
        return data;
      } else {
        print("❌ ERROR: ${data["message"] ?? "Failed to update schedule"}");
        print("✏️ ===================================");
        throw Exception(
          data["message"] ?? "Failed to update schedule",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("✏️ ===================================");
      rethrow;
    }
  }

  // DELETE SCHEDULE using roomId
  Future<Map<String, dynamic>> deleteSchedule({
    required String roomId,
  }) async {
    print("🗑️ ========== DELETE SCHEDULE ==========");
    print("⏰ TIME: ${DateTime.now()}");
    print("🆔 ROOM ID: $roomId");
    
    try {
      final token = await _getToken();
      final url = "$baseUrl/$roomId";

      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");
      print("📤 HEADERS: {Content-Type: application/json, Authorization: Bearer ***}");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ SUCCESS: Meeting deleted successfully");
        print("🗑️ ===================================");
        return data;
      } else {
        print("❌ ERROR: ${data["message"] ?? "Failed to delete schedule"}");
        print("🗑️ ===================================");
        throw Exception(
          data["message"] ?? "Failed to delete schedule",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("🗑️ ===================================");
      rethrow;
    }
  }

  // START MEETING using roomId
  Future<Map<String, dynamic>> startMeeting({
    required String roomId,
  }) async {
    print("▶️ ========== START MEETING ==========");
    print("⏰ TIME: ${DateTime.now()}");
    print("🆔 ROOM ID: $roomId");
    
    try {
      final token = await _getToken();
      final url = "$baseUrl/$roomId/start";

      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");
      print("📤 HEADERS: {Content-Type: application/json, Authorization: Bearer ***}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCESS: Meeting started successfully");
        print("📊 MEETING DATA: $data");
        print("▶️ ===================================");
        return data;
      } else {
        print("❌ ERROR: ${data["message"] ?? "Failed to start meeting"}");
        print("▶️ ===================================");
        throw Exception(
          data["message"] ?? "Failed to start meeting",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("▶️ ===================================");
      rethrow;
    }
  }
}