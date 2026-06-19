import 'package:flutter/material.dart';
import '../auth/bloc/auth_screen/login_screen.dart';

import '../screens/meeting_history.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.of(context).size.width * 0.75;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0B57D0)),
              accountName: const Text("User Name"),
              accountEmail: const Text("user@example.com"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40)),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.history), title: const Text("History"), onTap: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingHistoryScreen()));
            }),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () {}),
            const Spacer(),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,);
    },
    ),

          ],    ),
      ),
    );
  }
}