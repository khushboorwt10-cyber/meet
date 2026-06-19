import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/auth/bloc/auth_bloc.dart';
import 'package:meet_easyy/bloc/meeting_room_bloc/meeting_room_bloc.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/service/create_meeting_servic.dart';
import 'package:meet_easyy/screens/splash_screen.dart';
import 'auth/bloc/auth_service/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthService()),
        RepositoryProvider(create: (context) => MeetingService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              context.read<AuthService>(),
            ),
          ),

        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Meet_Easy',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home:  SplashScreen(),
        ),
      ),
    );
  }
}