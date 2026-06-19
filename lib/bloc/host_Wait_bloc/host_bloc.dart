// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../model/host_wait_model.dart';
// import 'package:zego_express_engine/zego_express_engine.dart';
//
// // Events
// abstract class HostEvent {}
// class AdmitUserEvent extends HostEvent { final String userId; AdmitUserEvent(this.userId); }
// class AddUserEvent extends HostEvent { final WaitingUser user; AddUserEvent(this.user); }
//
// // State
// class HostState {
//   final List<WaitingUser> waitingList;
//   HostState(this.waitingList);
// }
//
// // Bloc
// class HostApprovalBloc extends Bloc<HostEvent, HostState> {
//   HostApprovalBloc() : super(HostState([
//     WaitingUser(userId: "1", userName: "Rahul Sharma", isApproved: false),
//     WaitingUser(userId: "2", userName: "Priya Verma", isApproved: false),
//   ])) {
//
//     on<AdmitUserEvent>((event, emit) {
//       final updatedList = List<WaitingUser>.from(state.waitingList)
//         ..removeWhere((user) => user.userId == event.userId);
//       emit(HostState(updatedList));
//     });
//
//     on<AddUserEvent>((event, emit) {
//       final updatedList = List<WaitingUser>.from(state.waitingList)..add(event.user);
//       emit(HostState(updatedList));
//     });
//   }
//
//   void setupZegoListener() {
//     ZegoExpressEngine.onRoomUserUpdate = (roomID, updateType, userList) {
//       if (updateType == ZegoUpdateType.Add) {
//         for (final user in userList) {
//           add(AddUserEvent(WaitingUser(userId: user.userID, userName: user.userName, isApproved: false)));
//         }
//       }
//     };
//   }
// }