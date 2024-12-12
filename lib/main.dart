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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiveStreamPage(
                              key: UniqueKey(),
                              onExit: () {

                              }
                            ),
                        ),
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
                                  side: BorderSide(
                                    color: controller.connectedDevice?.id.id == data.device.id.id &&
                                        controller.isConnected.value
                                        ? Colors.green
                                        : controller.connectingDeviceId.value == data.device.id.toString() &&
                                        controller.isConnecting.value
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    data.device.name.isEmpty ? 'Unknown Device' : data.device.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data.device.id.id),
                                      Obx(() {
                                        if (controller.connectingDeviceId.value == data.device.id.toString() &&
                                            controller.isConnecting.value) {
                                          return Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Connecting...',
                                                style: TextStyle(color: Colors.orange),
                                              ),
                                            ],
                                          );
                                        } else if (controller.connectedDevice?.id.id == data.device.id.id &&
                                            controller.isConnected.value) {
                                          return Text(
                                            'Connected',
                                            style: TextStyle(color: Colors.green),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(data.rssi.toString()),
                                      SizedBox(width: 8),
                                      Obx(() {
                                        final isThisDeviceConnecting = controller.connectingDeviceId.value == data.device.id.toString() &&
                                            controller.isConnecting.value;
                                        final isThisDeviceConnected = controller.connectedDevice?.id.id == data.device.id.id &&
                                            controller.isConnected.value;

                                        return IconButton(
                                          icon: Icon(
                                            isThisDeviceConnected
                                                ? Icons.check_circle
                                                : isThisDeviceConnecting
                                                ? Icons.autorenew
                                                : Icons.bluetooth_connected,
                                            color: isThisDeviceConnected
                                                ? Colors.green
                                                : isThisDeviceConnecting
                                                ? Colors.orange
                                                : Colors.grey,
                                          ),
                                          onPressed: isThisDeviceConnecting || isThisDeviceConnected
                                              ? null
                                              : () => controller.connectToDevice(data.device),
                                        );
                                      }),
                                    ],
                                  ),
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

