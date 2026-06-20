import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/schedule_bloc/service/schedule_service.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleService service = ScheduleService();

  ScheduleBloc() : super(ScheduleInitial()) {
    on<GetScheduleEvent>(_getMeetings);
    on<AddScheduleEvent>(_createMeeting);
    on<UpdateScheduleEvent>(_updateMeeting);
    on<DeleteScheduleEvent>(_deleteMeeting);
    on<StartMeetingEvent>(_startMeeting);
  }

  Future<void> _getMeetings(
    GetScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    print("📋 ========== REFRESHING MEETINGS LIST ==========");
    emit(ScheduleLoading());

    try {
      final response = await service.getSchedules();
      List<MeetingModel> meetings =
          response.map((e) => MeetingModel.fromJson(e)).toList();
      print("✅ LOADED ${meetings.length} MEETINGS");
      emit(ScheduleLoaded(meetings));
    } catch (e) {
      print("❌ ERROR LOADING MEETINGS: $e");
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> _createMeeting(
    AddScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    print("➕ ========== CREATING MEETING ==========");
    print("📝 TOPIC: ${event.topic}");
    
    try {
      await service.createSchedule(
        topic: event.topic,
        description: event.description,
        scheduledDate: event.scheduledDate,
      );
      print("✅ CREATE SUCCESSFUL, REFRESHING LIST...");
      add(GetScheduleEvent());
    } catch (e) {
      print("❌ CREATE ERROR: $e");
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> _updateMeeting(
    UpdateScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    print("✏️ ========== UPDATING MEETING ==========");
    print("🆔 ROOM ID: ${event.roomId}");
    print("📝 TOPIC: ${event.topic}");
    
    try {
      await service.updateSchedule(
        roomId: event.roomId,
        topic: event.topic,
        description: event.description,
        scheduledDate: event.scheduledDate,
      );
      print("✅ UPDATE SUCCESSFUL, REFRESHING LIST...");
      add(GetScheduleEvent());
    } catch (e) {
      print("❌ UPDATE ERROR: $e");
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> _deleteMeeting(
    DeleteScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    print("🗑️ ========== DELETING MEETING ==========");
    print("🆔 ROOM ID: ${event.roomId}");
    
    try {
      await service.deleteSchedule(
        roomId: event.roomId,
      );
      print("✅ DELETE SUCCESSFUL, REFRESHING LIST...");
      add(GetScheduleEvent());
    } catch (e) {
      print("❌ DELETE ERROR: $e");
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> _startMeeting(
    StartMeetingEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    print("▶️ ========== STARTING MEETING ==========");
    print("🆔 ROOM ID: ${event.roomId}");
    
    try {
      final response = await service.startMeeting(
        roomId: event.roomId,
      );
      print("✅ MEETING STARTED SUCCESSFULLY");
      emit(MeetingStarted(response));
    } catch (e) {
      print("❌ START MEETING ERROR: $e");
      emit(ScheduleError(e.toString()));
    }
  }
}