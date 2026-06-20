class MeetingModel {
  final String id;
  final String roomId;
  final String topic;
  final String description;
  final DateTime scheduledDate;
  final int duration;
  final String createdBy;
  final String hostId;
  final bool waitingRoom;
  final String? meetingId;
  final String status; // upcoming, ongoing, completed
  final List<String> invitedEmails;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingModel({
    required this.id,
    required this.roomId,
    required this.topic,
    required this.description,
    required this.scheduledDate,
    required this.duration,
    required this.createdBy,
    required this.hostId,
    required this.waitingRoom,
    this.meetingId,
    required this.status,
    required this.invitedEmails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json["_id"] ?? "",
      roomId: json["roomId"] ?? "",
      topic: json["topic"] ?? "",
      description: json["description"] ?? "",
      scheduledDate: DateTime.parse(json["scheduledDate"]),
      duration: json["duration"] ?? 30,
      createdBy: json["createdBy"] ?? "",
      hostId: json["hostId"] ?? "",
      waitingRoom: json["waitingRoom"] ?? true,
      meetingId: json["meetingId"],
      status: json["status"] ?? "upcoming",
      invitedEmails: List<String>.from(json["invitedEmails"] ?? []),
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
    );
  }

  // Helper method to check if meeting can be started
  bool get canStart {
    final now = DateTime.now();
    return scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now);
  }

  // Helper method to get formatted time
  String get formattedTime {
    final hour = scheduledDate.hour;
    final minute = scheduledDate.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
  }

  // Helper method to get formatted date
  String get formattedDate {
    return "${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}";
  }
}
abstract class ScheduleState {}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<MeetingModel> meetings;

  ScheduleLoaded(this.meetings);
}

class ScheduleError extends ScheduleState {
  final String message;

  ScheduleError(this.message);
}

class MeetingStarted extends ScheduleState {
  final Map<String, dynamic> meetingData;

  MeetingStarted(this.meetingData);
}