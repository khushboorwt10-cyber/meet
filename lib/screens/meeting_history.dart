import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meet_easyy/bloc/homeBloc/meeting/meeting_service.dart';
import 'package:meet_easyy/screens/meeting_detail_s.dart';

const Color kPrimary = Color(0xFF0B57D0);
const Color kBackground = Color(0xFFF5F7FB);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class MeetingHistoryScreen extends StatefulWidget {
  const MeetingHistoryScreen({super.key});

  @override
  State<MeetingHistoryScreen> createState() =>
      _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState
    extends State<MeetingHistoryScreen> {

  final MeetingHistoryService service =
      MeetingHistoryService();

  List<dynamic> meetings = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await service.getMeetingHistory();

      setState(() {
        meetings = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      debugPrint("History Error => $e");
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";

    try {
      final d = DateTime.parse(date).toLocal();

      return DateFormat(
        'dd MMM yyyy • hh:mm a',
      ).format(d);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text(
          "Meeting History",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : meetings.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 250),
                      Center(
                        child: Text(
                          "No Meetings Found",
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {

                      final item = meetings[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.video_call,
                            ),
                          ),
                          title: Text(
                            item["topic"] ?? "Meeting",
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDate(
                                  item["createdAt"] ??
                                      item["scheduledDate"],
                                ),
                              ),
                              Text(
                                "Room ID : ${item["roomId"] ?? ""}",
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MeetingDetailsScreen(
      meetingData: {
        "title": item["topic"] ?? "",
        "description": item["description"] ?? "",
        "host": item["hostName"] ?? "",
        "members":
            "${item["participantsCount"] ?? 0}",
        "meetingId": item["roomId"] ?? "",
        "date": formatDate(
          item["scheduledDate"],
        ),
        "time": formatDate(
          item["scheduledDate"],
        ),
        "duration":
            item["duration"]?.toString() ?? "",
      },
    ),
  ),
);
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}