import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc()
      : super(HomeState(
    currentIndex: 0,
    meetings: [],
    isLoading: false,
    upcomingMeeting: null, // Initial state mein null rakhein
  )) {

    on<ChangeTabEvent>((event, emit) {
      emit(state.copyWith(currentIndex: event.index));
    });

    on<LoadMeetingsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        isLoading: false,
        meetings: List.generate(5, (i) => "Meeting ID: 12345$i"),
        upcomingMeeting: "Flutter UI Sync - 11:00 AM", // Data yahan set hoga
      ));
    });
  }
}