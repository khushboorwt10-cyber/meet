abstract class ScheduleEvent {}
class AddScheduleEvent extends ScheduleEvent {
  final DateTime date;
  final String title;
  final String time;
  AddScheduleEvent(this.date, this.title, this.time);
}