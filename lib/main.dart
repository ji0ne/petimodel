import 'package:firstnote/ble_controller.dart';
import 'package:firstnote/pet_eye_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';

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
      home: const PetProfileScreen(),
    );
  }
}

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final BleController controller = Get.put(BleController());
  RxString _movement = '정지'.obs;
  double _threshold1 = 0.5;
  double _threshold2 = 2.0;
  Timer? _timer;

  bool _isAlertShowing = false; //팝업창

  @override
  void initState() {
    super.initState();
    _startTimer();
    _monitorTemperature();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {  // 1초에서 2초로 변경
      if (controller.magnitudes.isNotEmpty) {
        // 최근 N개의 데이터만 사용하여 평균 계산
        List<double> recentMagnitudes = controller.magnitudes.length > 5
            ? controller.magnitudes.sublist(controller.magnitudes.length - 5)
            : controller.magnitudes;

        double averageMagnitude = recentMagnitudes.reduce((a, b) => a + b) / recentMagnitudes.length;

        // 상태 변경 로직에 히스테리시스 추가
        if (averageMagnitude < _threshold1) {
          _movement.value = '정지';
        } else if (averageMagnitude < _threshold2) {
          _movement.value = '걷기';
        } else {
          _movement.value = '뛰기';
        }

        // 일정 시간 동안 데이터가 없으면 정지 상태로 전환
        if (DateTime.now().difference(controller.lastUpdateTime) > Duration(seconds: 3)) {
          _movement.value = '정지';
        }

        controller.magnitudes.clear();
      } else {
        // 데이터가 없으면 정지 상태로 전환
        _movement.value = '정지';
      }
    });
  }

  void _monitorTemperature() {
    ever(controller.temperatureData, (String temp) {
      double temperature = double.tryParse(temp) ?? 0;
      if (temperature >= 36.8 && !_isAlertShowing) {
        _isAlertShowing = true;
        _showVitalIssueDialog();
      }
    });
  }

  // Alert Dialog 표시 함수
  void _showVitalIssueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _isAlertShowing = false;
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Image.asset(
                  'assets/dog-alert.png',  // 알림창에 표시할 강아지 이미지
                  width: 150,
                  height: 150,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '! Vital Issue !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '아이의 행동에 주의를 기울여 주세요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _isAlertShowing = false;
                          Navigator.of(context).pop();
                        },
                        child: Text('확인'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _sendPostRequest();
                          _isAlertShowing = false;
                          Navigator.of(context).pop();
                        },
                        child: Text('PET EYE'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendPostRequest() async {
    try {
      final response = await http.post(
        Uri.parse('http://devse.gonetis.com:12478/send-signal'),  // 제공받은 도메인 주소
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'signal': '1'}),
      );

      if (response.statusCode == 200) {
        print('Signal sent successfully');
        print('Server response: ${response.body}');  // 서버 응답 확인
      } else {
        print('Failed to send signal. Status code: ${response.statusCode}');
        print('Error response: ${response.body}');
      }
    } catch (e) {
      print('Error sending POST request: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                  const Text(
                    '오늘의 히로',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/hiro-profile.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  ),

                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '히로',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.male, color: Colors.blue),
                    ],
                  ),
                  const Text(
                    '2018.07.06',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  Obx(() {
                    return Image.asset(
                      _movement.value == '뛰기'
                          ? 'assets/running-dog-silhouette_47203.png'
                          : _movement.value == '걷기'
                          ? 'assets/dog-facing-right.png'
                          : 'assets/sitting-dog-icon.png',  // 정지 상태일 때의 이미지
                      width: 24,
                      height: 24,
                    );
                  }),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.black),
                      const SizedBox(width: 8),
                      Obx(() {
                        double bpm = double.tryParse(controller.s_bpm) ?? 0;
                        Color bpmColor = bpm >= 100 ? Colors.red : Colors.green;
                        return Text(
                          '${controller.s_bpm} bpm',
                          style: TextStyle(fontSize: 16, color: bpmColor),
                        );
                      }),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Obx(() {
                        double temp = double.tryParse(controller.s_temperature) ?? 0;
                        Color temperatureColor = temp >= 37.5 ? Colors.red : Colors.green;
                        return Text(
                          '${controller.s_temperature}°C',
                          style: TextStyle(fontSize: 16, color: temperatureColor),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: GetBuilder<BleController>(
                builder: (controller) {
                  return StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        List<ScanResult> filteredResults = snapshot.data!.where((result) {
                          String deviceName = result.device.name.toUpperCase();
                          return deviceName.contains('PET');
                        }).toList();

                        if (filteredResults.isEmpty) {
                          return const Center(child: Text("PET 기기를 찾을 수 없습니다"));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredResults.length,
                          itemBuilder: (context, index) {
                            final data = filteredResults[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(data.device.name.isEmpty ? 'Unknown Device' : data.device.name),
                                subtitle: Obx(() {
                                  if (controller.connectingDeviceId.value == data.device.id.id) {
                                    return Text(
                                      'Connecting...',
                                      style: TextStyle(color: Colors.orange),
                                    );
                                  } else if (controller.connectedDevice?.id.id == data.device.id.id &&
                                      controller.isConnected.value) {
                                    return Text(
                                      'Connected',
                                      style: TextStyle(color: Colors.green),
                                    );
                                  }
                                  return Text(data.device.id.id);
                                }),
                                trailing: Text(data.rssi.toString()),
                                onTap: () => controller.connectToDevice(data.device),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text("검색된 기기가 없습니다"));
                      }
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3EE),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      controller.scanDevices();
                    },
                    child: const Text('주변 기기 찾기'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3EE),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PetEyePage()),
                      );
                    },
                    child: const Text('PET-EYE'),
                  ),
                ],
              ),
            ),

            Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.notifications, color: Colors.white),
                  Icon(Icons.favorite, color: Colors.white),
                  Icon(Icons.menu, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}