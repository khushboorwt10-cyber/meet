abstract class NewMeetingState {}

class NewMeetingInitial extends NewMeetingState {}
class MeetingLoadingState extends NewMeetingState {}

class MeetingGeneratedState extends NewMeetingState {
  final String roomId;
  MeetingGeneratedState(this.roomId);
}

class MeetingErrorState extends NewMeetingState {
  final String error;
  MeetingErrorState(this.error);
}