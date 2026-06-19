class ParticipantModel {
  final String userId;
  final String name;
  final String status;
  final bool isLocal;

  bool isMuted;
  bool isVideoOff;

  // 🔥 NEW: Host + control features
  bool isHost;
  bool isRemoved;

  ParticipantModel({
    required this.userId,
    required this.name,
    this.status = 'active',
    this.isLocal = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isHost = false,
    this.isRemoved = false,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId']['_id'] ?? "",
      name: json['userId']['name'] ?? "",
      status: json['status'] ?? 'active',
      isLocal: false,

      // 🔥 backend se later control hoga
      isMuted: json['isMuted'] ?? false,
      isVideoOff: json['isVideoOff'] ?? false,

      // optional future backend support
      isHost: json['isHost'] ?? false,
      isRemoved: json['isRemoved'] ?? false,
    );
  }

  ParticipantModel copyWith({
    String? userId,
    String? name,
    String? status,
    bool? isLocal,
    bool? isMuted,
    bool? isVideoOff,
    bool? isHost,
    bool? isRemoved,
  }) {
    return ParticipantModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      isLocal: isLocal ?? this.isLocal,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isHost: isHost ?? this.isHost,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}