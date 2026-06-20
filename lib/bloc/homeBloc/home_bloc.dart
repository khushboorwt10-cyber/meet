import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/homeBloc/meeting/meeting_service.dart';
import 'package:meet_easyy/bloc/schedule_bloc/service/schedule_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ScheduleService scheduleService = ScheduleService();
  final MeetingHistoryService historyService =
      MeetingHistoryService();

  HomeBloc()
      : super(
         HomeState(
  currentIndex: 0,
  meetings: [],
  isLoading: false,
  userName: '',
)
        ) {
    on<ChangeTabEvent>((event, emit) {
      emit(state.copyWith(currentIndex: event.index));
    });

    on<LoadMeetingsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      try {
        final schedules =
            await scheduleService.getSchedules();

        final history =
            await historyService.getMeetingHistory();

        List<dynamic> recent = [];

        if (history.isNotEmpty) {
          recent = history.take(4).toList();
        }

        String? upcomingMeeting;
        String? roomId;
        bool canJoin = false;

        if (schedules.isNotEmpty) {
          schedules.sort(
            (a, b) => DateTime.parse(a["scheduledDate"])
                .compareTo(
              DateTime.parse(b["scheduledDate"]),
            ),
          );

          final meeting = schedules.first;

          final scheduledDate =
              DateTime.parse(meeting["scheduledDate"])
                  .toLocal();

          canJoin = DateTime.now().isAfter(
            scheduledDate.subtract(
              const Duration(minutes: 10),
            ),
          );

          upcomingMeeting =
              "${meeting["topic"]}\n"
              "${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}"
              " ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}";

          roomId = meeting["roomId"];
        }

        emit(
          state.copyWith(
            isLoading: false,
            upcomingMeeting: upcomingMeeting,
            roomId: roomId,
            canJoin: canJoin,
            recentMeetings: recent,
          ),
        );
      } catch (e) {
        print(e);

        emit(
          state.copyWith(
            isLoading: false,
          ),
        );
      }
    });
  }
}