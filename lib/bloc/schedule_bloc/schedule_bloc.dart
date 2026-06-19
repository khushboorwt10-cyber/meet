import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_event.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  Map<DateTime, List<Map<String, String>>> schedules = {};

  ScheduleBloc() : super(ScheduleInitial()) {
    on<AddScheduleEvent>((event, emit) {
      emit(ScheduleLoading());
      final day = DateTime(event.date.year, event.date.month, event.date.day);

      if (schedules[day] != null) {
        schedules[day]!.add({"title": event.title, "time": event.time});
      } else {
        schedules[day] = [{"title": event.title, "time": event.time}];
      }
      emit(ScheduleLoaded(Map.from(schedules)));
    });
  }
}