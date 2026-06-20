import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/meeting_room_bloc/meeting_scren.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/service/create_meeting_servic.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/new_meeting_model.dart';
import '../meeting_room_bloc/meeting_room_bloc.dart';
import 'new_meet_bloc.dart';
import 'new_meet_event.dart';
import 'new_meet_state.dart';

const Color kPrimary = Color(0xFF0B57D0);
const Color kSurface = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class NewMeetingScreen extends StatefulWidget {
  const NewMeetingScreen({super.key});

  @override
  State<NewMeetingScreen> createState() => _NewMeetingScreenState();
}

class _NewMeetingScreenState extends State<NewMeetingScreen> {
 String userName = "";

  String userId = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName =
          prefs.getString("user_name") ?? "Host";

      userId =
          prefs.getString("user_id") ?? "";
    });
  }

  @override
  
  Widget build(BuildContext context) {
    
    return BlocProvider(
      create: (context) => NewMeetingBloc(MeetingService()),

    child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: kSurface,
          elevation: 0,
          centerTitle: true,
          title: const Text("Create Meeting", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      body: BlocBuilder<NewMeetingBloc, NewMeetingState>(
        builder: (context, state) {
          if (state is MeetingErrorState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

          final bool isLoading = state is MeetingLoadingState;

          final String? roomId = (state is MeetingGeneratedState) ? state.roomId : null;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  const Center(
                    child: Text("Ready to start a session?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextPrimary)),
                  ),
                  const SizedBox(height: 8),
                  const Text("Generate an ID and share it with your team.", style: TextStyle(color: kTextSecondary, fontSize: 14)),
                  const SizedBox(height: 30),

                  // Generate/Regenerate Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<NewMeetingBloc>().add(CreateMeetingEvent()),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(roomId == null ? "Generate Meeting ID" : "Regenerate ID",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Meeting ID Card
                  if (roomId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text("MEETING ID", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                          const SizedBox(height: 10),
                          Text(roomId, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: kPrimary)),

                          const SizedBox(height: 20),

                          // Details Section
                          _buildDetailRow(Icons.lock_outline, "End-to-end encrypted session"),
                          _buildDetailRow(Icons.videocam_outlined, "HD Video & Audio enabled"),
                          _buildDetailRow(Icons.people_outline, "Max 50 participants allowed"),

                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                          // Copy & Share Buttons
                          Row(
                            children: [
                              _buildActionButton(context, "Copy", Icons.copy, () {
                                Clipboard.setData(ClipboardData(text: roomId));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                              }),
                              const SizedBox(width: 12),
                              _buildActionButton(context, "Share", Icons.share_rounded, () async {
                                try {
                                  final service = context.read<MeetingService>();
                                  final data = await service.shareMeeting(roomId);
                                  await Share.share(data['shareText']);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Start Button
                  // Start Button ke andar meetingId ko roomId se change karein
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom( 
                        backgroundColor: roomId == null ? Colors.grey.shade400 : kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    onPressed: roomId == null
    ? null
    : () {
        final hostId = userId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => MeetingBloc(
                roomId: roomId,
              ),
              child: MeetingRoomScreen(
              meeting: MeetingModel2(
  roomId: roomId,
  userId: hostId,
  userName: userName,
  isHost: true,
  status: "active",
),
              ),
            ),
          ),
        );
      },
                      child: const Text(
                        "Start Meeting",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kTextSecondary),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}