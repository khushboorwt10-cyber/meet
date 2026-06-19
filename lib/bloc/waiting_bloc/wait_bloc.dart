import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/waiting_bloc/service/waiting_Service.dart';

///---------------STATES--------------
abstract class WaitingRoomState {}

class WaitingInitial extends WaitingRoomState {}

class WaitingState extends WaitingRoomState {}

class ApprovedState extends WaitingRoomState {}

class RejectedState extends WaitingRoomState {}

///---------------EVENTS--------------
abstract class WaitingRoomEvent {}

class CheckApprovalEvent extends WaitingRoomEvent {
  final String meetingId;
  final String userId;

  CheckApprovalEvent({
    required this.meetingId,
    required this.userId,
  });
}

class ApprovalReceivedEvent extends WaitingRoomEvent {}

class RejectionReceivedEvent extends WaitingRoomEvent {}

///---------------BLOC--------------
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState> {
  final WaitingService _service = WaitingService();
  Timer? _timer;

  WaitingRoomBloc() : super(WaitingInitial()) {
    /// Start polling
    on<CheckApprovalEvent>((event, emit) async {
      emit(WaitingState());

      _timer?.cancel();

      _timer = Timer.periodic(
        const Duration(seconds: 3),
            (timer) async {
          if (isClosed) {
            timer.cancel();
            return;
          }

          try {
            final status = await _service.checkWaitingStatus(
              event.meetingId,
              event.userId,
            );

            if (status == 'approved') {
              timer.cancel();
              debugPrint("🔥 APPROVAL DETECTED");
              add(ApprovalReceivedEvent());
            } else if (status == 'rejected') {
              timer.cancel();
              debugPrint("🔥 REJECTION DETECTED");
              add(RejectionReceivedEvent());
            }
          } catch (e) {
            debugPrint("Error: $e");
          }
        },
      );
    });

    /// Approved State
    on<ApprovalReceivedEvent>((event, emit) {
      debugPrint("🔥 APPROVED STATE EMITTED");
      emit(ApprovedState());
    });

    /// Rejected State
    on<RejectionReceivedEvent>((event, emit) {
      debugPrint("🔥 REJECTED STATE EMITTED");
      emit(RejectedState());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}