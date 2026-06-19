class MeetingModel {
  final String meetingId;
  final String roomId;
  final String title;
  final String meetingLink;

  MeetingModel({
    required this.meetingId,
    required this.roomId,
    required this.title,
    required this.meetingLink,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      meetingId: json['meeting']['meetingId'],
      roomId: json['meeting']['roomId'],
      title: json['meeting']['title'],
      meetingLink: json['meetingLink'],
    );
  }
}