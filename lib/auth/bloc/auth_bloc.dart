
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_event.dart';
import 'auth_service/auth_service.dart';
import 'auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  AuthBloc(this.authService) : super(AuthInitial()) {

    on<LoginEvent>((event, emit) async {
  emit(AuthLoading());

  try {
    final res = await authService.login(
      event.email,
      event.password,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', res['token']);

    // API se jo name aa raha hai usko save karo
    await prefs.setString(
      'user_name',
      res['user']['name'],
    );

    await prefs.setString(
      'user_id',
      res['user']['_id'],
    );

    emit(AuthSuccess("Login Success"));
  } catch (e) {
    emit(AuthError(
      e.toString().replaceAll("Exception: ", ""),
    ));
  }
});
    
    on<RegisterEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await authService.register(event.user);
        emit(AuthSuccess("Registered Successfully"));
      } catch (e) { emit(AuthError("Registration Failed")); }
    });
  }
}