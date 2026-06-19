abstract class NewMeetingEvent {}

class CreateMeetingEvent extends NewMeetingEvent {} // Ye use karein

class ShareMeetingEvent extends NewMeetingEvent {
  final String roomId;
  ShareMeetingEvent(this.roomId);
}