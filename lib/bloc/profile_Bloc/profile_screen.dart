import 'package:flutter/material.dart';
import 'package:meet_easyy/bloc/profile_Bloc/privacy.dart';
import 'package:meet_easyy/bloc/profile_Bloc/service/profile_service.dart';
import '../../auth/bloc/auth_screen/login_screen.dart';
import '../../screens/notification_screen.dart';
import 'edit_profile.dart';
import 'help_&_support.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _profileService.getProfile();
      print("📊 PROFILE DATA: $data");
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ ERROR: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
            onPressed: _fetchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: const Color(0xFFE0E7FF),
                            backgroundImage:
                                _userData != null &&
                                    _userData!['photo'] != null &&
                                    _userData!['photo'].isNotEmpty
                                ? NetworkImage(_userData!['photo'])
                                : null,
                            child:
                                (_userData == null ||
                                    _userData!['photo'] == null ||
                                    _userData!['photo'].isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.indigo,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _userData?['name'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userData?['email'] ?? 'user@example.com',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Active User",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Stats Section
                    Row(
                      children: [
                        _statCard("Meetings", "12", Icons.video_call),
                        _statCard("Hours", "5h", Icons.timer),
                        _statCard("Rating", "4.8", Icons.star),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Settings Section
                    _menuTile(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(userData: _userData),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _userData = result;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profile updated!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),

                    _menuTile(
                      icon: Icons.lock_outline,
                      title: "Privacy",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),

                    _menuTile(
                      icon: Icons.notifications_none,
                      title: "Notifications",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),

                    _menuTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.black),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:meet_easyy/bloc/profile_Bloc/privacy.dart';
// import '../../auth/bloc/auth_screen/login_screen.dart';
// import '../../screens/notification_screen.dart';
// import 'edit_profile.dart';
// import 'help_&_support.dart';


// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           "Profile",
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//       ),

//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(25),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(25),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   children: [

//                     const CircleAvatar(
//                       radius: 45,
//                       backgroundColor: Color(0xFFE0E7FF),
//                       child: Icon(
//                         Icons.person,
//                         size: 50,
//                         color: Colors.indigo,
//                       ),
//                     ),

//                     const SizedBox(height: 15),

//                     const Text(
//                       "Khushboo Rawat",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),

//                     const SizedBox(height: 5),

//                     Text(
//                       "khushboo@example.com",
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Text(
//                         "Active User",
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 25),

//               // 📊 STATS SECTION
//               Row(
//                 children: [
//                   _statCard("Meetings", "12", Icons.video_call),
//                   _statCard("Hours", "5h", Icons.timer),
//                   _statCard("Rating", "4.8", Icons.star),
//                 ],
//               ),

//               const SizedBox(height: 25),

//               // ⚙️ SETTINGS SECTION
//               _menuTile(
//                 icon: Icons.person_outline,
//                 title: "Edit Profile",
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const EditProfileScreen()),
//                   );
//                 },
//               ),

//               _menuTile(
//                 icon: Icons.lock_outline,
//                 title: "Privacy",
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const PrivacyScreen()),
//                   );
//                 },
//               ),

//               _menuTile(
//                 icon: Icons.notifications_none,
//                 title: "Notifications",
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const NotificationScreen()),
//                   );
//                 },
//               ),

//               _menuTile(
//                 icon: Icons.help_outline,
//                 title: "Help & Support",
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const HelpSupportScreen()),
//                   );
//                 },
//               ),
//               const SizedBox(height: 40),

//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
//                   },
//                   icon: const Icon(Icons.logout),
//                   label: const Text("Logout"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }


//   Widget _statCard(String title, String value, IconData icon) {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 5),
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//             )
//           ],
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.indigo),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 18,
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               title,
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _menuTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 6,
//             )
//           ],
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.indigo),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios, size: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }