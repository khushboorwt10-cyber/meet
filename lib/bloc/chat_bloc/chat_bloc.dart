import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatState([])) {

    on<SendMessageEvent>((event, emit) {

      final updatedMessages =
      List<Map<String, dynamic>>.from(state.messages)
        ..add({
          "text": event.message,
          "isMe": true,
          "time": "Now",
        });

      emit(ChatState(updatedMessages));

      Future.delayed(const Duration(seconds: 1), () {
        add(
          ReceiveMessageEvent(
            "Got your message 👍",
          ),
        );
      });
    });

    on<ReceiveMessageEvent>((event, emit) {

      final updatedMessages =
      List<Map<String, dynamic>>.from(state.messages)
        ..add({
          "text": event.message,
          "isMe": false,
          "time": "Now",
        });

      emit(ChatState(updatedMessages));
    });
  }
}