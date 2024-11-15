import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'pet_list_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordCheckController = TextEditingController();

  String? _name, _phoneNumber, _email, _password, _passwordCheck;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _passwordCheckController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordCheckController.dispose();
    super.dispose();
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

  Future<void> _signUpRequest() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final response = await http.post(
        Uri.parse('${Config.getServerURL()}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _name,
          'phoneNumber': _phoneNumber,
          'email': _email,
          'password': _password,
        }),
      );

      final result = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception(result['message']);
      }

      _showAlert('회원가입 성공', '$_name님 환영합니다!', () {
        // PetListPage로 교체하면서 이전 스택의 모든 페이지 제거
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PetListPage(),
          ),
          (Route<dynamic> route) => false, // 이전 스택의 모든 페이지 제거
        );
      });
    } catch (error) {
      _showAlert('회원가입 실패', error.toString(), null);
    }
  }

  Widget _buildTextFormField(
    String hint,
    TextEditingController controller,
    Function(String?) onSaved,
    String? Function(String?) validator, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFFEA5A2D)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFFEA5A2D), width: 2),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? const Icon(Icons.check, color: const Color(0xFFEA5A2D))
              : null,
        ),
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '가입을 진행하기 위해\n아래의 정보를 입력해 주세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildTextFormField(
                    '이름을 입력해주세요',
                    _nameController,
                    (value) => _name = value,
                    (value) => value!.isEmpty ? '이름을 입력하여 주세요.' : null,
                  ),
                  _buildTextFormField(
                    '전화번호를 입력해주세요',
                    _phoneController,
                    (value) => _phoneNumber = value,
                    (value) =>
                        !RegExp(r'^010[0-9]{3,4}[0-9]{4}$').hasMatch(value!)
                            ? '유효하지 않은 전화번호입니다.'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {/* 인증 로직 구현 */},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA5A2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('인증번호 전송',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    '이메일 주소를 입력해주세요',
                    _emailController,
                    (value) => _email = value,
                    (value) =>
                        !RegExp(r'^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$')
                                .hasMatch(value!)
                            ? '유효하지 않은 이메일입니다.'
                            : null,
                  ),
                  _buildTextFormField(
                    '비밀 번호 입력',
                    _passwordController,
                    (value) => _password = value,
                    (value) =>
                        !RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d!@#$%]{8,12}$')
                                .hasMatch(value!)
                            ? '비밀번호 형식 불만족'
                            : null,
                    obscureText: true,
                  ),
                  _buildTextFormField(
                    '비밀 번호 확인',
                    _passwordCheckController,
                    (value) => _passwordCheck = value,
                    (value) =>
                        value != _passwordController.text ? '비밀번호 불일치' : null,
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _signUpRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA5A2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('시작',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
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
