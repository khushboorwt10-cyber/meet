import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/auth/bloc/auth_bloc.dart';
import 'package:meet_easyy/auth/bloc/auth_event.dart';
import 'package:meet_easyy/auth/bloc/auth_state.dart';

import 'model/auth_model.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController(); // Naya Controller
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Premium Input Decoration
  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF0B57D0)),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0B57D0), width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Get Started 👋", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E))),
                  const SizedBox(height: 8),
                  const Text("Create your account to join Meet_Easy", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 40),

                  TextField(controller: nameController, decoration: _inputDecor("Full Name", Icons.person_outline)),
                  const SizedBox(height: 15),
                  TextField(controller: emailController, decoration: _inputDecor("Email Address", Icons.email_outlined)),
                  const SizedBox(height: 15),
                  TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _inputDecor("Phone Number", Icons.phone_outlined)),
                  const SizedBox(height: 15),
                  TextField(controller: passwordController, obscureText: true, decoration: _inputDecor("Password", Icons.lock_outline)),

                  const SizedBox(height: 30),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B57D0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final user = UserModel(
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                password: passwordController.text
                            );
                            context.read<AuthBloc>().add(RegisterEvent(user));
                          },
                          child: state is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF0B57D0), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}