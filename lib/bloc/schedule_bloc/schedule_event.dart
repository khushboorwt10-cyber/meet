abstract class ScheduleEvent {}

class GetScheduleEvent extends ScheduleEvent {}

class AddScheduleEvent extends ScheduleEvent {
  final String topic;
  final String description;
  final DateTime scheduledDate;

  AddScheduleEvent({
    required this.topic,
    required this.description,
    required this.scheduledDate,
  });
}

class UpdateScheduleEvent extends ScheduleEvent {
  final String roomId;
  final String topic;
  final String description;
  final DateTime scheduledDate;

  UpdateScheduleEvent({
    required this.roomId,
    required this.topic,
    required this.description,
    required this.scheduledDate,
  });
}

class DeleteScheduleEvent extends ScheduleEvent {
  final String roomId;

  DeleteScheduleEvent({
    required this.roomId,
  });
}

class StartMeetingEvent extends ScheduleEvent {
  final String roomId;

  StartMeetingEvent({
    required this.roomId,
  });
}