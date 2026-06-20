
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/chat_bloc/chat_service.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';


const Color primaryColor = Color(0xFF0B57D0);
const Color textColorPrimary = Color(0xFF1E293B);
const Color surfaceColor = Color(0xFFF8FAFC);



class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> users = [
      {
        "name": "Rahul Sharma",
        "message": "Hey! Are you coming?",
        "time": "2:30 PM"
      },
      {
        "name": "Priya Verma",
        "message": "Meeting at 5 PM",
        "time": "1:10 PM"
      },
      {
        "name": "Khushi Rawat",
        "message": "Send me notes",
        "time": "Yesterday"
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Chats",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return GestureDetector(
            // onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => ChatScreen(
            //         userName: user["name"]!,
            //       ),
            //     ),
            //   );
            // },
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        userName: user["name"]!,
        roomId: "MEETING_ROOM_ID_HERE", 
        userId: "CURRENT_USER_ID_HERE", 
        userEmail: "CURRENT_USER_EMAIL_HERE",
      ),
    ),
  );
},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user["name"]![0],
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user["name"]!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user["message"]!,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    user["time"]!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userName;
  final String roomId;
  final String userId;
  final String userEmail;
  
  const ChatScreen({
    super.key,
    required this.userName,
    required this.roomId,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late ChatService chatService;
  late ChatBloc chatBloc;

  @override
  void initState() {
    super.initState();
    
    // Initialize chat service
    chatService = ChatService();
    chatService.initSocket(widget.userId, widget.userName, widget.userEmail);
    
    // Create ChatBloc instance
    chatBloc = ChatBloc(chatService: chatService)
      ..add(JoinRoomEvent(
        roomId: widget.roomId,
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ));
    
    // Set up scroll listener for pagination
    scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      final state = chatBloc.state;
      if (!state.isLoading) {
        chatBloc.add(LoadMoreMessagesEvent(roomId: widget.roomId));
      }
    }
  }
  
  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    chatBloc.close(); // Close the bloc
    chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: chatBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: const BackButton(color: Colors.black),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0B57D0),
                child: Text(
                  widget.userName[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    "Online",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.isLoading && state.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    controller: scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      
                      final msg = state.messages[index];
                      return Align(
                        alignment: msg["isMe"] 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg["isMe"] ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(msg["isMe"] ? 16 : 4),
                              bottomRight: Radius.circular(msg["isMe"] ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Show sender name for received messages
                              if (!msg["isMe"] && msg.containsKey('senderName'))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    msg['senderName'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              Text(
                                msg["text"],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(msg["time"]),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (msg["isMe"] && msg.containsKey('status'))
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        msg['status'] == 'sent' 
                                            ? Icons.done_all 
                                            : Icons.access_time,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Type a message",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onSubmitted: (value) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF0B57D0),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
  
  void _sendMessage() {
    if (controller.text.trim().isEmpty) return;
    
    // Access the ChatBloc directly through the chatBloc variable
    chatBloc.add(SendMessageEvent(controller.text.trim()));
    controller.clear();
  }
  
  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time;
    }
  }
}
// class ChatScreen extends StatelessWidget {
//   final String userName;

//   ChatScreen({
//     super.key,
//     required this.userName,
//   });

//   final TextEditingController controller =
//   TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => ChatBloc(),
//       child: Scaffold(
//         backgroundColor: Colors.white,

//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: Colors.white,

//           leading: const BackButton(
//             color: Colors.black,
//           ),

//           title: Row(
//             children: [
//               CircleAvatar(
//                 backgroundColor: primaryColor,
//                 child: Text(
//                   userName[0],
//                   style: const TextStyle(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 10),

//               Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     userName,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),

//                   const Text(
//                     "Online",
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 12,
//                     ),
//                   )
//                 ],
//               )
//             ],
//           ),
//         ),

//         body: Column(
//           children: [

//             Expanded(
//               child:
//               BlocBuilder<ChatBloc, ChatState>(
//                 builder: (context, state) {
//                   return ListView.builder(
//                     reverse: false,
//                     padding:
//                     const EdgeInsets.all(15),
//                     itemCount:
//                     state.messages.length,
//                     itemBuilder:
//                         (context, index) {

//                       final msg =
//                       state.messages[index];

//                       return Align(
//                         alignment: msg["isMe"]
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,

//                         child: Container(
//                           constraints:
//                           const BoxConstraints(
//                             maxWidth: 280,
//                           ),

//                           margin:
//                           const EdgeInsets.only(
//                             bottom: 10,
//                           ),

//                           padding:
//                           const EdgeInsets.all(
//                             12,
//                           ),

//                           decoration:
//                           BoxDecoration(
//                             color: msg["isMe"]
//                                 ? Colors.blue
//                                 : Colors.yellow,

//                             borderRadius:
//                             BorderRadius.only(
//                               topLeft:
//                               const Radius.circular(
//                                   16),

//                               topRight:
//                               const Radius.circular(
//                                   16),

//                               bottomLeft:
//                               Radius.circular(
//                                 msg["isMe"]
//                                     ? 16
//                                     : 4,
//                               ),

//                               bottomRight:
//                               Radius.circular(
//                                 msg["isMe"]
//                                     ? 4
//                                     : 16,
//                               ),
//                             ),

//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black
//                                     .withOpacity(
//                                     0.05),
//                                 blurRadius: 6,
//                               )
//                             ],
//                           ),

//                           child: Column(
//                             crossAxisAlignment:
//                             CrossAxisAlignment
//                                 .end,
//                             children: [
//                               Text(
//                                 msg["text"],
//                                 style:
//                                 const TextStyle(
//                                   fontSize: 15,
//                                   color:
//                                   textColorPrimary,
//                                 ),
//                               ),

//                               const SizedBox(
//                                   height: 4),

//                               Text(
//                                 msg["time"],
//                                 style:
//                                 const TextStyle(
//                                   fontSize: 10,
//                                   color:
//                                   Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),

//             Container(
//               padding:
//               const EdgeInsets.symmetric(
//                 horizontal: 10,
//                 vertical: 8,
//               ),

//               decoration: const BoxDecoration(
//                 color: Colors.white,
//               ),

//               child: Row(
//                 children: [

//                   Expanded(
//                     child: TextField(
//                       controller: controller,

//                       decoration:
//                       InputDecoration(
//                         hintText:
//                         "Type a message",

//                         filled: true,

//                         fillColor:
//                         Colors.grey.shade100,

//                         border:
//                         OutlineInputBorder(
//                           borderRadius:
//                           BorderRadius.circular(
//                               30),
//                           borderSide:
//                           BorderSide.none,
//                         ),

//                         contentPadding:
//                         const EdgeInsets
//                             .symmetric(
//                           horizontal: 20,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 10),

//                   CircleAvatar(
//                     radius: 24,
//                     backgroundColor:
//                     primaryColor,

//                     child: IconButton(
//                       onPressed: () {

//                         if (controller.text
//                             .trim()
//                             .isEmpty) return;

//                         context
//                             .read<ChatBloc>()
//                             .add(
//                           SendMessageEvent(
//                             controller.text,
//                           ),
//                         );

//                         controller.clear();
//                       },
//                       icon: const Icon(
//                         Icons.send,
//                         color: Colors.white,
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }