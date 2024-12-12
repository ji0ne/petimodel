import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _rememberLogin = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadRememberMe();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final response =
          await http.get(Uri.parse('${Config.getServerURL()}/auth'));
      final result = json.decode(response.body);
      if (result.containsKey('user')) {
        Navigator.pushReplacementNamed(context, '/pet_list');
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberLogin = prefs.getBool('rememberMe') ?? false;
      if (_rememberLogin) {
        _idController.text = prefs.getString('inputEmail') ?? '';
      }
    });
  }

  void _showAlert(String title, String message, VoidCallback? onOk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loginRequest(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.getServerURL()}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final result = json.decode(response.body);
      if (response.statusCode != 200) {
        throw Exception(result['message']);
      }

      _showAlert('로그인 성공', '${result['user']['username']}님 반갑습니다.', () {
        Navigator.pushReplacementNamed(context, '/pet_list');
      });

      if (_rememberLogin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', _rememberLogin);
        await prefs.setString('inputEmail', email);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('rememberMe');
        await prefs.remove('inputEmail');
      }
    } catch (error) {
      _showAlert('로그인 실패', '일치하는 회원정보가 없습니다.', null);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Image.asset(
            'assets/background.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset('assets/peti-text-icon-w.png', height: 60),
                  const Spacer(flex: 2),
                  _buildTextField('ID', '이메일 주소를 입력해주세요', _idController),
                  const SizedBox(height: 20),
                  _buildTextField('PW', '비밀번호를 입력해주세요', _pwController,
                      isPassword: true),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberLogin,
                        onChanged: (bool? value) async {
                          setState(() => _rememberLogin = value ?? false);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('rememberMe', _rememberLogin);
                        },
                        activeColor: const Color(0xFFEA5A2D),
                        checkColor: Colors.white,
                      ),
                      const Text('로그인 정보 저장',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_idController.text.isEmpty) {
                        _showAlert('경고', '이메일을 입력해주세요', null);
                        return;
                      }
                      if (_pwController.text.isEmpty) {
                        _showAlert('경고', '비밀번호를 입력해주세요', null);
                        return;
                      }
                      _loginRequest(_idController.text, _pwController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA5A2D),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/sign_up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '이메일로 회원가입',
                      style: TextStyle(
                          color: Color(0xFFEA5A2D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(flex: 3),
                  TextButton(
                    onPressed: () {
                      // ID/PW 찾기 로직 구현
                    },
                    child: const Text(
                      'ID / 비밀번호 찾기 >',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
