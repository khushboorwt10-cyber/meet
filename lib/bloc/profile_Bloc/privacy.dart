import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {

  bool micOn = true;
  bool cameraOn = true;
  bool chatVisible = true;
  bool dataSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Privacy & Security",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Manage your privacy settings 🔒",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔐 PRIVACY CARD
            _sectionCard(
              title: "Meeting Controls",
              children: [

                _switchTile(
                  icon: Icons.mic,
                  title: "Microphone",
                  subtitle: "Allow mic access during meeting",
                  value: micOn,
                  onChanged: (val) => setState(() => micOn = val),
                ),

                _switchTile(
                  icon: Icons.videocam,
                  title: "Camera",
                  subtitle: "Allow camera access",
                  value: cameraOn,
                  onChanged: (val) => setState(() => cameraOn = val),
                ),

                _switchTile(
                  icon: Icons.chat,
                  title: "Chat Visibility",
                  subtitle: "Allow others to message you",
                  value: chatVisible,
                  onChanged: (val) => setState(() => chatVisible = val),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 📊 DATA CARD
            _sectionCard(
              title: "Data & Permissions",
              children: [

                _switchTile(
                  icon: Icons.security,
                  title: "Data Sharing",
                  subtitle: "Allow app to improve experience",
                  value: dataSharing,
                  onChanged: (val) => setState(() => dataSharing = val),
                ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Clear Chat History",style: TextStyle(color: Colors.black),),
                  subtitle: const Text("Delete all messages permanently",style: TextStyle(color: Colors.black),),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat cleared")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🚫 BLOCKED USERS
            _sectionCard(
              title: "Blocked Users",
              children: [

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: const Text("John Doe",style: TextStyle(color: Colors.black),),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text("Unblock",style: TextStyle(color: Colors.deepPurple),),
                  ),
                ),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title:  Text("Alexa",style: TextStyle(color: Colors.black),),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text("Unblock",style: TextStyle(color: Colors.deepPurple),
                  ),
    ),
                ),
              ],

                ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 SECTION CARD
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }

  // 🔥 SWITCH TILE
  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.deepPurple,
      secondary: Icon(icon,color: Colors.blue,),
      title: Text(title,style:
        TextStyle(color: Colors.black),),
      subtitle: Text(subtitle,style:
        TextStyle(color: Colors.black),),
    );
  }
}