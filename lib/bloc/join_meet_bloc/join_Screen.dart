import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../waiting_bloc/wait_bloc.dart';
import '../waiting_bloc/waiting_Screen.dart';
import 'join_meet_bloc.dart';

class JoinMeetingScreen extends StatelessWidget {
  final TextEditingController meetingController = TextEditingController();

  JoinMeetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JoinMeetingBloc(),
      child:BlocListener<JoinMeetingBloc, JoinMeetingState>(
          listener: (context, state) {
            if (state is JoinSuccess) {
              print("ParticipantId => ${state.data.participantId}");
              print("UserId => ${state.userId}");
              print("UserName => ${state.userName}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (context) => WaitingRoomBloc()..add(CheckApprovalEvent(
                      meetingId: state.data.roomId,
                      userId: state.data.participantId,
                    )),
                    child: WaitingRoomScreen(
                      meetingId: state.data.roomId,
                      participantId: state.data.participantId,
                      waitingApproval: true,
                      userId: state.userId,
                      userName: state.userName,
                    ),
                  ),
                ),
              );
            } else if (state is JoinError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }

        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          appBar: AppBar(
              title: const Text("Join Meeting",
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Join a meeting 🔗",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05), blurRadius: 8)
                      ]),
                  child: TextField(
                    controller: meetingController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                        hintText: "Enter Meeting ID",
                        border: InputBorder.none
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                BlocBuilder<JoinMeetingBloc, JoinMeetingState>(
                  builder: (context, state) => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: state is JoinLoading
                          ? null
                          : () {
                        if (meetingController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Enter Meeting ID")));
                          return;
                        }
                        context
                            .read<JoinMeetingBloc>()
                            .add(RequestJoinEvent(meetingController.text));
                      },
                      child: state is JoinLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Join Meeting",
                          style:
                          TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}