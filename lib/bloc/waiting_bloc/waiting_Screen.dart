  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../model/new_meeting_model.dart';
  import '../meeting_room_bloc/meeting_room_bloc.dart';
import '../meeting_room_bloc/meeting_scren.dart';
  import '../waiting_bloc/wait_bloc.dart';

  const Color kPrimary = Colors.deepPurple;
  class WaitingRoomScreen extends StatelessWidget {
    final String meetingId;
    final String participantId;
    final String userId;
    final String userName;
    final bool waitingApproval;

    const WaitingRoomScreen({
      super.key,
      required this.meetingId,
      required this.participantId,
      required this.userId,
      required this.userName,
      required this.waitingApproval,
    });
    @override
    Widget build(BuildContext context) {
      return BlocListener<WaitingRoomBloc, WaitingRoomState>(
        listener: (context, state) {
          if (state is ApprovedState) {
            debugPrint("🔥 NAVIGATING TO MEETING ROOM");
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => MeetingBloc(
                      roomId: meetingId,
                    ),
                      child: MeetingRoomScreen(
                  meeting: MeetingModel2(
                    roomId: meetingId,
                    userId: userId,
                    userName: userName,
                    isHost: false,
                    status: "active",
                  ),
                ),
                  ),
              ),
            );
          } else if (state is RejectedState) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Access Denied"),
                content: const Text("The host has rejected your request to join."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text("OK"),
                  )
                ],
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimary),
                  const SizedBox(height: 30),
                  const Text(
                    "Waiting for Host approval...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please stay on this screen. You will join the meeting as soon as the host approves.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }