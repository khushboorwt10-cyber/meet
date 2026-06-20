// lib/bloc/chat_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/chat_bloc/chat_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService chatService;
  String? roomId;
  String? userId;
  String? userName;
  String? userEmail;
  int currentPage = 1;
  bool hasMoreMessages = true;
  bool isLoadingMore = false;
  
  ChatBloc({required this.chatService}) : super(ChatState([])) {
    // Set up socket listeners
    setupSocketListeners();
    
    on<JoinRoomEvent>((event, emit) {
      roomId = event.roomId;
      userId = event.userId;
      userName = event.userName;
      userEmail = event.userEmail;
      
      // Join the room via socket
      chatService.joinRoom(
        event.roomId, 
        event.userId, 
        event.userName, 
        event.userEmail
      );
      
      // Load chat history
      add(LoadChatHistoryEvent(roomId: event.roomId));
    });
    
    on<SendMessageEvent>((event, emit) async {
      if (event.message.trim().isEmpty) return;
      
      // Add message locally first for instant feedback
      final updatedMessages = List<Map<String, dynamic>>.from(state.messages)
        ..add({
          "text": event.message,
          "isMe": true,
          "time": DateTime.now().toIso8601String(),
          "status": "sending", // Track message status
          "_id": DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        });
      
      emit(ChatState(updatedMessages));
      
      // Send message via socket
      if (roomId != null && userId != null) {
        chatService.sendMessage(roomId!, userId!, event.message);
      }
    });
    
    on<ReceiveMessageEvent>((event, emit) {
      final updatedMessages = List<Map<String, dynamic>>.from(state.messages)
        ..add({
          "text": event.message,
          "isMe": false,
          "time": event.createdAt ?? DateTime.now().toIso8601String(),
          "_id": event.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          "senderName": event.senderName ?? 'Unknown',
          "senderId": event.senderId,
        });
      
      emit(ChatState(updatedMessages));
    });
    
    on<LoadChatHistoryEvent>((event, emit) async {
      try {
        emit(state.copyWith(isLoading: true));
        
        final response = await chatService.getChatHistory(
          event.roomId,
          page: event.page ?? 1,
          limit: event.limit ?? 50,
        );
        
        if (response['success']) {
          final chats = List<Map<String, dynamic>>.from(response['chats']);
          
          // Convert backend messages to our format
          final formattedMessages = chats.map((chat) {
            return {
              "text": chat['message'],
              "isMe": chat['senderId'] == userId,
              "time": chat['createdAt'],
              "_id": chat['_id'],
              "senderName": chat['senderName'],
              "senderId": chat['senderId'],
            };
          }).toList();
          
          // Combine with existing messages, avoiding duplicates
          final existingIds = state.messages.map((m) => m['_id']).toSet();
          final newMessages = formattedMessages.where((m) => !existingIds.contains(m['_id'])).toList();
          
          final allMessages = [...state.messages, ...newMessages];
          allMessages.sort((a, b) => a['time'].compareTo(b['time']));
          
          hasMoreMessages = response['page'] < response['totalPages'];
          currentPage = response['page'];
          
          emit(ChatState(allMessages, isLoading: false));
        }
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
        ));
      }
    });
    
    on<LoadMoreMessagesEvent>((event, emit) async {
      if (isLoadingMore || !hasMoreMessages) return;
      
      isLoadingMore = true;
      final nextPage = currentPage + 1;
      
      try {
        final response = await chatService.getChatHistory(
          event.roomId,
          page: nextPage,
          limit: event.limit ?? 50,
        );
        
        if (response['success']) {
          final chats = List<Map<String, dynamic>>.from(response['chats']);
          
          final formattedMessages = chats.map((chat) {
            return {
              "text": chat['message'],
              "isMe": chat['senderId'] == userId,
              "time": chat['createdAt'],
              "_id": chat['_id'],
              "senderName": chat['senderName'],
              "senderId": chat['senderId'],
            };
          }).toList();
          
          final existingIds = state.messages.map((m) => m['_id']).toSet();
          final newMessages = formattedMessages.where((m) => !existingIds.contains(m['_id'])).toList();
          
          final allMessages = [...state.messages, ...newMessages];
          allMessages.sort((a, b) => a['time'].compareTo(b['time']));
          
          hasMoreMessages = response['page'] < response['totalPages'];
          currentPage = response['page'];
          
          emit(ChatState(allMessages, isLoading: false));
        }
      } catch (e) {
        // Handle error
      } finally {
        isLoadingMore = false;
      }
    });
    
    on<UpdateMessageStatusEvent>((event, emit) {
      final updatedMessages = state.messages.map((msg) {
        if (msg['_id'] == event.tempId) {
          return {...msg, 'status': 'sent', '_id': event.realId};
        }
        return msg;
      }).toList();
      
      emit(ChatState(updatedMessages));
    });
  }
  
  void setupSocketListeners() {
    // Listen for incoming messages
    chatService.onReceiveMessage((data) {
      add(ReceiveMessageEvent(
        message: data['message'],
        messageId: data['_id'],
        senderId: data['senderId'],
        senderName: data['senderName'],
        createdAt: data['createdAt'],
      ));
    });
    
    // Listen for errors
    chatService.onMessageError((error) {
      // Handle error - show snackbar or something
      print('Message Error: $error');
    });
  }
  
  void dispose() {
    chatService.disconnect();
  }
}
// import 'dart:async';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'chat_event.dart';
// import 'chat_state.dart';

// class ChatBloc extends Bloc<ChatEvent, ChatState> {
//   ChatBloc() : super(ChatState([])) {

//     on<SendMessageEvent>((event, emit) {

//       final updatedMessages =
//       List<Map<String, dynamic>>.from(state.messages)
//         ..add({
//           "text": event.message,
//           "isMe": true,
//           "time": "Now",
//         });

//       emit(ChatState(updatedMessages));

//       Future.delayed(const Duration(seconds: 1), () {
//         add(
//           ReceiveMessageEvent(
//             "Got your message 👍",
//           ),
//         );
//       });
//     });

//     on<ReceiveMessageEvent>((event, emit) {

//       final updatedMessages =
//       List<Map<String, dynamic>>.from(state.messages)
//         ..add({
//           "text": event.message,
//           "isMe": false,
//           "time": "Now",
//         });

//       emit(ChatState(updatedMessages));
//     });
//   }
// }