import 'auth_screen/model/auth_model.dart';

abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String email, password;
  LoginEvent(this.email, this.password);
}
class RegisterEvent extends AuthEvent {
  final UserModel user;
  RegisterEvent(this.user);
}