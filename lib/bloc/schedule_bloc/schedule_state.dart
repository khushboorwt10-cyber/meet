abstract class ScheduleState {}
class ScheduleInitial extends ScheduleState {}
class ScheduleLoading extends ScheduleState {}
class ScheduleLoaded extends ScheduleState {
  final Map<DateTime, List<Map<String, String>>> schedules;
  ScheduleLoaded(this.schedules);
}