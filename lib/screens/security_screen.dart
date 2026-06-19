import 'package:flutter/material.dart';
import 'package:meet_easyy/screens/change_password_screen.dart';
import 'package:meet_easyy/screens/manage_device.dart';

// Professional Palette
const Color kPrimary = Color(0xFF0B57D0);
const Color kSurface = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool is2FAEnabled = false;
  bool isLockEnabled = true;
  bool isRecordingProtected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        title: const Text("Security", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.security, color: kPrimary, size: 28)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Account Secure", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Manage privacy & protection", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text("Security Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
            const SizedBox(height: 15),

            _buildSwitchTile("2FA Authentication", "Extra security for login", Icons.verified_user, is2FAEnabled, (val) => setState(() => is2FAEnabled = val)),
            _buildSwitchTile("App Lock", "Use PIN / Fingerprint", Icons.lock, isLockEnabled, (val) => setState(() => isLockEnabled = val)),
            _buildSwitchTile("Secure Recordings", "Protect saved video files", Icons.videocam, isRecordingProtected, (val) => setState(() => isRecordingProtected = val)),

            const SizedBox(height: 25),
            const Text("Privacy & Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
            const SizedBox(height: 15),

            _buildActionTile("Change Password", Icons.key, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
            _buildActionTile("Manage Devices", Icons.devices, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDevicesScreen()))),
            _buildActionTile("Logout All Devices", Icons.logout, Colors.redAccent, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String sub, IconData icon, bool val, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: kPrimary),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)), Text(sub, style: const TextStyle(color: kTextSecondary, fontSize: 12))])),
          Switch(value: val, activeColor: kPrimary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.white,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}