import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/new_meet_Screen.dart';
import 'package:meet_easyy/screens/meeting_detail_s.dart';
import 'package:meet_easyy/screens/meeting_history.dart';
import 'package:meet_easyy/screens/saved_screen.dart';
import 'package:meet_easyy/screens/security_screen.dart';
import '../../drawer/custom_drawer.dart';
import '../../screens/notification_screen.dart';
import '../join_meet_bloc/join_Screen.dart';
import '../profile_Bloc/profile_screen.dart';
import '../schedule_bloc/schedule_screen.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

const Color kPrimary = Color(0xFF0B57D0);
const Color kSurface = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadMeetingsEvent()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final screens = [
            _buildMeetTab(context, state),
            ScheduleScreen(),
            ProfileScreen(),
          ];

          return PopScope(
            canPop: state.currentIndex == 0,
            onPopInvoked: (didPop) {
              if (!didPop && state.currentIndex != 0) {
                context.read<HomeBloc>().add(ChangeTabEvent(0));
              }
            },
            child: Scaffold(
              backgroundColor: kSurface,
              drawer: Drawer(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(color: kPrimary),
                      child: Text(
                        "Meet_Easy Menu",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("About"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Logout"),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: screens[state.currentIndex],
              ),

              bottomNavigationBar: BottomNavigationBar(
                currentIndex: state.currentIndex,
                onTap: (index) {
                  context.read<HomeBloc>().add(ChangeTabEvent(index));
                },
                selectedItemColor: kPrimary,
                unselectedItemColor: kTextSecondary,
                backgroundColor: Colors.white,
                type: BottomNavigationBarType.fixed,
                elevation: 8,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_call),
                    label: "Meet",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month),
                    label: "Schedule",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetTab(BuildContext context, HomeState state) {
    return Scaffold(
      backgroundColor: kSurface,
      drawer: CustomDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: kPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Meet_Easy",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(LoadMeetingsEvent());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: kPrimary,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${state.userName}!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const Text(
                "Let's manage your meetings today.",
                style: TextStyle(color: kTextSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),

              if (state.upcomingMeeting != null) ...[
                const Text(
                  "Upcoming Meeting",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: kPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          state.upcomingMeeting!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: state.canJoin
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NewMeetingScreen(),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.canJoin
                              ? kPrimary
                              : Colors.black,
                          elevation: 0,
                        ),
                        child: Text(
                          state.canJoin ? "Join" : "Waiting",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  _buildMainButton(
                    context,
                    "New Meeting",
                    Icons.video_call,
                    true,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NewMeetingScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildMainButton(
                    context,
                    "Join Meeting",
                    Icons.add,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JoinMeetingScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _quickActionTile(
                    "Schedule",
                    Icons.calendar_month,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ScheduleScreen()),
                    ),
                  ),
                  _quickActionTile(
                    "History",
                    Icons.history,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MeetingHistoryScreen()),
                    ),
                  ),
                  _quickActionTile(
                    "Security",
                    Icons.security,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SecurityScreen()),
                    ),
                  ),
                  _quickActionTile(
                    "Saved",
                    Icons.bookmark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecordingsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Meetings",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MeetingHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "View All",
                      style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.recentMeetings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meeting = state.recentMeetings[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailsScreen(
                            meetingData: {
                              "title": meeting["topic"] ?? "",
                              "host": meeting["hostName"] ?? "",
                              "meetingId": meeting["roomId"] ?? "",
                              "description": meeting["description"] ?? "",
                              "date": meeting["scheduledDate"] ?? "",
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting["topic"] ?? "Meeting",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(meeting["createdAt"] ?? ""),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context,
    String title,
    IconData icon,
    bool isPrimary,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: SizedBox(
        height: 80,
        child: Material(
          color: isPrimary ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : kPrimary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
