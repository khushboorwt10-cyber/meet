// lib/bloc/chat_state.dart
class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;
  
  ChatState(
    this.messages, {
    this.isLoading = false,
    this.error,
  });
  
  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
// class ChatState {
//   final List<Map<String, dynamic>> messages;

//   ChatState(this.messages);
// }