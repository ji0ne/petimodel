import 'package:petimodel/ble_controller.dart';
import 'package:petimodel/live_stream_page.dart';
import 'package:petimodel/pet_eye_page.dart';
import 'package:petimodel/behavior_prediction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';
import 'health_assessment.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'notification_service.dart';

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
  late final HealthAssessment healthAssessment; // HealthAssessment 인스턴스 추가
  RxString _movement = '정지'.obs;

  Timer? _timer;
  Timer? _healthCheckTimer; // _healthCheckTimer 변수 추가

  bool _isAlertShowing = false; //팝업창

  @override
  void initState() {
    super.initState();
    _startTimer();
    healthAssessment = HealthAssessment(controller);
    _startHealthCheckTimer();
    NotificationService().initialize();
  }


  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {  // 더 빠른 업데이트를 위해 500ms로 변경
      String behavior = controller.behaviorPrediction.predictedBehavior.value;
      _movement.value = behavior;  // 직접 값 할당 (이미 '정지', '걷기', '뛰기' 중 하나)
    });
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // 심박수 체크로 변경
      double bpm = double.tryParse(controller.bpmData.value) ?? 0;
      if (bpm >= 100) {  // 100 BPM 이상일 때
        NotificationService().showBpmAlert(controller.bpmData.value);
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
                  width: 100,
                  height: 100,
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
    _healthCheckTimer?.cancel();
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LiveStreamPage()),
                      );
                    },
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
                    final currentState = controller.behaviorPrediction.predictedBehavior.value;
                    return Image.asset(
                      currentState == '뛰기'
                          ? 'assets/running-dog-silhouette_47203.png'
                          : currentState == '걷기'
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