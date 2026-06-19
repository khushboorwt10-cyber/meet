import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meet_easyy/bloc/join_meet_bloc/service/join_meet_service.dart';
import 'model/join_meet_model.dart';

///--------------Events---------------
abstract class JoinMeetingEvent {}

class RequestJoinEvent extends JoinMeetingEvent {
  final String meetingId;
  RequestJoinEvent(this.meetingId);
}

///---------------States--------------
abstract class JoinMeetingState {}

class JoinInitial extends JoinMeetingState {}

class JoinLoading extends JoinMeetingState {}

class JoinSuccess extends JoinMeetingState {
  final JoinMeetingResponse data;
  final String userId;
  final String userName;

  JoinSuccess(
      this.data,
      this.userId,
      this.userName,
      );
}

class JoinError extends JoinMeetingState {
  final String message;
  JoinError(this.message);
}

///-------------Bloc------------------
class JoinMeetingBloc extends Bloc<JoinMeetingEvent, JoinMeetingState> {
  final ApiService _apiService = ApiService();

  JoinMeetingBloc() : super(JoinInitial()) {
    on<RequestJoinEvent>((event, emit) async {
      emit(JoinLoading());

      try {
        final prefs = await SharedPreferences.getInstance();

        String? token = prefs.getString('auth_token');

        if (token == null) {
          emit(JoinError("User not logged in"));
          return;
        }

        final response = await _apiService.joinMeeting(
          event.meetingId,
          token,
        );

        if (response.success) {
          String? userId = prefs.getString('user_id');
          String? userName = prefs.getString('user_name');

          print("================================");
          print("LOCAL USER ID => $userId");
          print("LOCAL USER NAME => $userName");
          print("================================");

          emit(
            JoinSuccess(
              response,
              userId ?? '',
              userName ?? '',
            ),
          );
        } else {
          emit(JoinError(response.message));
        }
      } catch (e) {
        emit(JoinError(e.toString()));
      }
    });
  }
}