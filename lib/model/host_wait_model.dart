class WaitingUser {
  final String userId;
  final String userName;
  final bool isApproved;

  WaitingUser({required this.userId, required this.userName, required this.isApproved});

  factory WaitingUser.fromMap(String id, Map<String, dynamic> data) {
    return WaitingUser(
      userId: id,
      userName: data['userName'] ?? 'Unknown',
      isApproved: data['isApproved'] ?? false,
    );
  }
}