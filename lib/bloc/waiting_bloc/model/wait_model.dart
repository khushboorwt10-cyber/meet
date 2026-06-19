class WaitingParticipant {
  final String id;
  final String name;
  final String userId;

  WaitingParticipant({required this.id, required this.name, required this.userId});

  factory WaitingParticipant.fromJson(Map<String, dynamic> json) {
    return WaitingParticipant(
      id: json['_id'],
      name: json['userId']['name'],
      userId: json['userId']['_id'],
    );
  }
}