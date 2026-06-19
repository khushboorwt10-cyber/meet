class JoinMeetingResponse {
  final bool success;
  final bool waitingApproval;
  final String message;
  final String roomId;
  final String meetingId;
  final String participantId;
  final String userId;

  JoinMeetingResponse({
    required this.success,
    required this.waitingApproval,
    required this.message,
    required this.roomId,
    required this.meetingId,
    required this.participantId,
    required this.userId,
  });

  factory JoinMeetingResponse.fromJson(Map<String, dynamic> json) {
    return JoinMeetingResponse(
      success: json['success'] ?? false,
      waitingApproval: json['waitingApproval'] ?? false,
      message: json['message'] ?? '',
      roomId: json['roomId'] ?? '',
      meetingId: json['meetingId'] ?? '',
      participantId: json['participantId'] ?? '',
      userId: json['userId'] ?? '',
    );
  }
}