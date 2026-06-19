import 'package:flutter/material.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/new_meet_Screen.dart';



const Color kPrimary = Color(0xFF0B57D0);
const Color kBackground = Color(0xFFF5F7FB);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class MeetingHistoryScreen extends StatelessWidget {
  const MeetingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> history = [
      {
        "title": "Team Meeting",
        "date": "12 May",
        "time": "5:00 PM",
        "duration": "45 min",
        "host": "Khushboo Rawat",
        "members": "12",
        "meetingId": "TM-458721",
        "description":
        "Weekly team sync to discuss project progress and upcoming tasks."
      },
      {
        "title": "Morning Meeting",
        "date": "10 May",
        "time": "2:00 PM",
        "duration": "45 min",
        "host": "Karishma Dhasmana",
        "members": "14",
        "meetingId": "TM-1223344",
        "description":
        "Weekly team sync to discuss project progress and upcoming tasks."
      },
    ];

    return Scaffold(
      backgroundColor: kBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimary,
        centerTitle: true,
        title: const Text(
          "Meeting History",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];

          return InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeetingDetailScreen(
                    meetingData: item,
                  ),
                ),
              );
            },

            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),

              child: Row(
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: const Icon(
                      Icons.video_camera_front_rounded,
                      color: kPrimary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          item["title"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${item["date"]} • ${item["time"]}",
                          style: const TextStyle(
                            color: kTextSecondary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Duration : ${item["duration"]}",
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.grey,
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


class MeetingDetailScreen extends StatelessWidget {
  final Map<String, String> meetingData;

  const MeetingDetailScreen({
    super.key,
    required this.meetingData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,

      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text(
          "Meeting Details",
          style: TextStyle(color: Colors.white),
        ),
      ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),

              child: Column(
                children: [

                  Container(
                    height: 70,
                    width: 70,

                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.video_call,
                      color: kPrimary,
                      size: 35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    meetingData["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    meetingData["description"] ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildInfoTile(
                    Icons.person,
                    "Host",
                    meetingData["host"] ?? "",
                  ),

                  _buildInfoTile(
                    Icons.people_alt_rounded,
                    "Participants",
                    "${meetingData["members"]} Members",
                  ),

                  _buildInfoTile(
                    Icons.calendar_month,
                    "Date",
                    meetingData["date"] ?? "",
                  ),

                  _buildInfoTile(
                    Icons.access_time,
                    "Time",
                    meetingData["time"] ?? "",
                  ),

                  _buildInfoTile(
                    Icons.timer,
                    "Duration",
                    meetingData["duration"] ?? "",
                  ),

                  _buildInfoTile(
                    Icons.vpn_key_rounded,
                    "Meeting ID",
                    meetingData["meetingId"] ?? "",
                  ),

                  _buildInfoTile(
                    Icons.check_circle,
                    "Status",
                    "Completed",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SizedBox(
            //   width: double.infinity,
            //   height: 55,
            //
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: kPrimary,
            //       shape: RoundedRectangleBorder(
            //         borderRadius:
            //         BorderRadius.circular(15),
            //       ),
            //     ),
            //
            //     onPressed: () {
            //       Navigator.push(context, MaterialPageRoute(builder: (context)=> NewMeetingScreen()));
            //     },
            //
            //     icon: const Icon(
            //       Icons.replay,
            //       color: Colors.white,
            //     ),
            //
            //     label: const Text(
            //       "Join Again",
            //       style: TextStyle(
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
           // ),
          ],
        ),
      ),
        ),
    );
  }
  Widget _buildInfoTile(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: kPrimary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }
}