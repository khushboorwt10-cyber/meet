import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String baseUrl = "https://meet-2zo9.onrender.com/api/auth";

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // GET PROFILE
  Future<Map<String, dynamic>> getProfile() async {
    print("📋 ========== GET PROFILE ==========");
    try {
      final token = await _getToken();
      final url = "$baseUrl/profile";

      print("🌐 URL: $url");
      print("🔑 TOKEN: ${token != null ? 'Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'No token'}");

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
        // Check if data has user object or direct fields
        if (data.containsKey('user')) {
          print("✅ SUCCESS: Profile fetched successfully with user object");
          return data['user']; // Return user object
        } else {
          print("✅ SUCCESS: Profile fetched successfully");
          return data; // Return direct data
        }
      } else {
        throw Exception(data["message"] ?? "Failed to fetch profile");
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      rethrow;
    }
  }

  // UPDATE PROFILE with Multipart (for photo upload)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    File? photo,
  }) async {
    print("✏️ ========== UPDATE PROFILE ==========");
    try {
      final token = await _getToken();
      final url = "$baseUrl/profile";

      // Validate phone number (exactly 10 digits)
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhone.length != 10) {
        throw Exception("Phone number must be exactly 10 digits");
      }

      print("🌐 URL: $url");
      print("📝 NAME: $name");
      print("📝 PHONE: $cleanedPhone");
      print("📷 PHOTO: ${photo != null ? photo.path : 'No photo'}");

      var request = http.MultipartRequest('PUT', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['phone'] = cleanedPhone;

      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo.path),
        );
      }

      print("📤 SENDING REQUEST...");
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: $responseBody");

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        print("✅ SUCCESS: Profile updated successfully");
        return data;
      } else {
        throw Exception(data["message"] ?? "Failed to update profile");
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfileJson({
    required String name,
    required String phone,
  }) async {
    print("✏️ ========== UPDATE PROFILE JSON ==========");
    try {
      final token = await _getToken();
      final url = "$baseUrl/profile";

      // Validate phone number (exactly 10 digits)
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhone.length != 10) {
        throw Exception("Phone number must be exactly 10 digits");
      }

      final body = {
        "name": name,
        "phone": cleanedPhone,
      };

      print("🌐 URL: $url");
      print("📤 BODY: ${jsonEncode(body)}");

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
        print("✅ SUCCESS: Profile updated successfully");
        return data;
      } else {
        throw Exception(data["message"] ?? "Failed to update profile");
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      rethrow;
    }
  }
}