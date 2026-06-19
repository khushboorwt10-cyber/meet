// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../screens/meeting_room_screen.dart';
// import '../meeting_room_bloc/meeting_scren.dart';
// import 'host_bloc.dart';
//
//
// const Color kPrimary = Color(0xFF0B57D0);
// const Color kSurface = Color(0xFFF8FAFC);
// class HostApprovalScreen extends StatefulWidget {
//   @override
//   _HostApprovalScreenState createState() => _HostApprovalScreenState();
// }
//
// class _HostApprovalScreenState extends State<HostApprovalScreen> {
//   @override
//   void initState() {
//     super.initState();
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => HostApprovalBloc(),
//       child: Builder(
//         builder: (context) => Scaffold(
//           backgroundColor: kSurface,
//           appBar: AppBar(
//             backgroundColor: kPrimary,
//             title: const Text("Waiting Room", style: TextStyle(color: Colors.white)),
//             elevation: 0,
//           ),
//           body: Column(
//             children: [
//               Expanded(
//                 child: BlocBuilder<HostApprovalBloc, HostState>(
//                   builder: (context, state) {
//                     if (state.waitingList.isEmpty) {
//                       return const Center(child: Text("No users waiting", style: TextStyle(color: Colors.grey)));
//                     }
//                     return ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: state.waitingList.length,
//                       itemBuilder: (context, index) {
//                         final user = state.waitingList[index];
//                         return Card(
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           margin: const EdgeInsets.only(bottom: 12),
//                           child: ListTile(
//                             leading: CircleAvatar(backgroundColor: kPrimary.withOpacity(0.1), child: const Icon(Icons.person, color: kPrimary)),
//                             title: Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: const Text("Waiting for approval"),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
//                               onPressed: () => context.read<HostApprovalBloc>().add(AdmitUserEvent(user.userId)),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               // START MEETING BUTTON
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 55,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
//                     onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(
//                         builder: (_) => BlocProvider.value(
//                           value: context.read<HostApprovalBloc>(),
//                           child: const MeetingRoomScreen(),
//                         ),
//                       ));
//                     },
//                     child: const Text("Start Meeting", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }