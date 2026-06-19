import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/service/create_meeting_servic.dart';
import 'new_meet_event.dart';
import 'new_meet_state.dart';
class NewMeetingBloc extends Bloc<NewMeetingEvent, NewMeetingState> {
  final MeetingService meetingService;

  NewMeetingBloc(this.meetingService) : super(NewMeetingInitial()) {

    on<CreateMeetingEvent>((event, emit) async {
      emit(MeetingLoadingState());
      try {
        final res = await meetingService.createMeeting();
        if (res['success'] == true && res['meeting'] != null) {
          emit(MeetingGeneratedState(res['meeting']['roomId']));
        } else {
          emit(MeetingErrorState(res['message'] ?? "Unknown Error"));
        }
      } catch (e) {
        emit(MeetingErrorState(e.toString().replaceAll("Exception: ", "")));
      }
    });

    on<ShareMeetingEvent>((event, emit) async {
      try {
        final data = await meetingService.shareMeeting(event.roomId);
      } catch (e) {
        emit(MeetingErrorState("Sharing failed"));
      }
    });
  }
}