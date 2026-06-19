class HomeState {
  final int currentIndex;
  final List<String> meetings;
  final bool isLoading;
  final String? upcomingMeeting;

  HomeState({
    required this.currentIndex,
    required this.meetings,
    required this.isLoading,
    this.upcomingMeeting,
  });

  HomeState copyWith({
    int? currentIndex,
    List<String>? meetings,
    bool? isLoading,
    String? upcomingMeeting,
  }) {
    return HomeState(
      currentIndex: currentIndex ?? this.currentIndex,
      meetings: meetings ?? this.meetings,
      isLoading: isLoading ?? this.isLoading,
      upcomingMeeting: upcomingMeeting ?? this.upcomingMeeting,
    );
  }
}