// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'start_user_page.dart';
import 'pet_main_page.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import 'pet_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/login': (context) => const LoginPage(), // 로그인 페이지 route
        '/sign_up': (context) => const SignUpPage(), // 회원가입 페이지 route
        '/pet_list': (context) => const PetListPage(),
      },
    );
  }
}
