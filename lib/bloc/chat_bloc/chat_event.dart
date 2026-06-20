// lib/bloc/chat_event.dart
abstract class ChatEvent {}

class JoinRoomEvent extends ChatEvent {
  final String roomId;
  final String userId;
  final String userName;
  final String userEmail;
  
  JoinRoomEvent({
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });
}

class SendMessageEvent extends ChatEvent {
  final String message;
  
  SendMessageEvent(this.message);
}

class ReceiveMessageEvent extends ChatEvent {
  final String message;
  final String? messageId;
  final String? senderId;
  final String? senderName;
  final String? createdAt;
  
  ReceiveMessageEvent({
    required this.message,
    this.messageId,
    this.senderId,
    this.senderName,
    this.createdAt,
  });
}

class LoadChatHistoryEvent extends ChatEvent {
  final String roomId;
  final int? page;
  final int? limit;
  
  LoadChatHistoryEvent({
    required this.roomId,
    this.page = 1,
    this.limit = 50,
  });
}

class LoadMoreMessagesEvent extends ChatEvent {
  final String roomId;
  final int? limit;
  
  LoadMoreMessagesEvent({
    required this.roomId,
    this.limit = 50,
  });
}

class UpdateMessageStatusEvent extends ChatEvent {
  final String tempId;
  final String realId;
  
  UpdateMessageStatusEvent({
    required this.tempId,
    required this.realId,
  });
}
// abstract class ChatEvent {}

// class SendMessageEvent extends ChatEvent {
//   final String message;

//   SendMessageEvent(this.message);
// }

// class ReceiveMessageEvent extends ChatEvent {
//   final String message;

//   ReceiveMessageEvent(this.message);
// }