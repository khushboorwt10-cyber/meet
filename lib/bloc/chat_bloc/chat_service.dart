// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  static const String baseUrl = 'http://your-backend-url.com/api'; // Replace with your URL
  static const String socketUrl = 'http://your-backend-url.com'; // Replace with your URL
  
  late IO.Socket socket;
  String? currentRoomId;
  String? currentUserId;
  
  // Initialize socket connection
  void initSocket(String userId, String userName, String userEmail) {
    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    socket.connect();
    
    // Store user info for later use
    currentUserId = userId;
  }
  
  // Join room
  void joinRoom(String roomId, String userId, String userName, String userEmail) {
    currentRoomId = roomId;
    socket.emit('join-room', {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
    });
  }
  
  // Send message
  void sendMessage(String roomId, String userId, String message) {
    socket.emit('send-message', {
      'roomId': roomId,
      'userId': userId,
      'message': message,
    });
  }
  
  // Leave room
  void leaveRoom(String roomId, String userId, String userName) {
    socket.emit('leave-room', {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
    });
  }
  
  // Listen for messages
  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    socket.on('receive-message', (data) {
      callback(data);
    });
  }
  
  // Listen for participants
  void onRoomParticipants(Function(List<dynamic>) callback) {
    socket.on('room-participants', (data) {
      callback(data['participants']);
    });
  }
  
  // Listen for user joined
  void onUserJoined(Function(Map<String, dynamic>) callback) {
    socket.on('user-joined', (data) {
      callback(data);
    });
  }
  
  // Listen for user left
  void onUserLeft(Function(Map<String, dynamic>) callback) {
    socket.on('user-left', (data) {
      callback(data);
    });
  }
  
  // Listen for errors
  void onMessageError(Function(String) callback) {
    socket.on('message-error', (data) {
      callback(data['error']);
    });
  }
  
  // Disconnect socket
  void disconnect() {
    if (currentRoomId != null && currentUserId != null) {
      leaveRoom(currentRoomId!, currentUserId!, 'User');
    }
    socket.disconnect();
  }
  
  // Fetch chat history from API
  Future<Map<String, dynamic>> getChatHistory(String roomId, {int page = 1, int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meeting/chat/$roomId?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add your auth token
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      throw Exception('Error fetching chat history: $e');
    }
  }
}