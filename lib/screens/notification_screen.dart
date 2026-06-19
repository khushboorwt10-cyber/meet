import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [

          _notificationTile(
            icon: Icons.video_call,
            title: "Meeting Started",
            subtitle: "Your meeting has started",
            time: "2 min ago",
            color: Colors.green,
          ),

          _notificationTile(
            icon: Icons.schedule,
            title: "Upcoming Meeting",
            subtitle: "Meeting at 5:00 PM",
            time: "1 hr ago",
            color: Colors.orange,
          ),

          _notificationTile(
            icon: Icons.chat,
            title: "New Message",
            subtitle: "You received a new message",
            time: "3 hr ago",
            color: Colors.blue,
          ),

          _notificationTile(
            icon: Icons.call_missed,
            title: "Missed Call",
            subtitle: "You missed a meeting",
            time: "Yesterday",
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // 🔔 Notification Tile UI
  Widget _notificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [

          // 🔔 Icon Circle
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 12),

          // 📄 Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),


          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}