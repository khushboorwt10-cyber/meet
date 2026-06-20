class ScheduleMeetingModel {
  bool? success;
  String? message;
  ScheduledMeeting? scheduledMeeting;
  String? meetingLink;
  String? webLink;

  ScheduleMeetingModel({
    this.success,
    this.message,
    this.scheduledMeeting,
    this.meetingLink,
    this.webLink,
  });

  ScheduleMeetingModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];

    scheduledMeeting = json['scheduledMeeting'] != null
        ? ScheduledMeeting.fromJson(json['scheduledMeeting'])
        : null;

    meetingLink = json['meetingLink'];
    webLink = json['webLink'];
  }
}

class ScheduledMeeting {
  String? id;
  String? roomId;
  String? topic;
  String? description;
  String? scheduledDate;
  int? duration;
  bool? waitingRoom;
  String? status;

  ScheduledMeeting({
    this.id,
    this.roomId,
    this.topic,
    this.description,
    this.scheduledDate,
    this.duration,
    this.waitingRoom,
    this.status,
  });

  ScheduledMeeting.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    roomId = json['roomId'];
    topic = json['topic'];
    description = json['description'];
    scheduledDate = json['scheduledDate'];
    duration = json['duration'];
    waitingRoom = json['waitingRoom'];
    status = json['status'];
  }
}