class HomeState {
  final int currentIndex;
  final List<dynamic> recentMeetings;
  final List<String> meetings;
  final bool isLoading;
  final String? upcomingMeeting;
  final bool canJoin;
  final String? roomId;
  final String userName;

  HomeState({
    required this.currentIndex,
    required this.meetings,
    required this.isLoading,
    this.upcomingMeeting,
    this.canJoin = false,
    this.roomId,
    this.recentMeetings = const [], required this.userName,
  });
HomeState copyWith({
  int? currentIndex,
  List<String>? meetings,
  bool? isLoading,
  String? upcomingMeeting,
  bool? canJoin,
  String? roomId,
  List<dynamic>? recentMeetings,
  String? userName,
}) {
  return HomeState(
    currentIndex: currentIndex ?? this.currentIndex,
    meetings: meetings ?? this.meetings,
    isLoading: isLoading ?? this.isLoading,
    upcomingMeeting: upcomingMeeting ?? this.upcomingMeeting,
    canJoin: canJoin ?? this.canJoin,
    roomId: roomId ?? this.roomId,
    recentMeetings: recentMeetings ?? this.recentMeetings,
    userName: userName ?? this.userName,
  );
}
}