import 'package:firstnote/ble_controller.dart';
import 'package:firstnote/pet_eye_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

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
  String _movement = '정지';
  double _threshold1 = 1.0;
  double _threshold2 = 5.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (controller.magnitudes.isNotEmpty) {
        double averageMagnitude = controller.magnitudes.reduce((a, b) => a + b) / controller.magnitudes.length;
        setState(() {
          if (averageMagnitude < _threshold1) {
            _movement = '정지';
          } else if (averageMagnitude < _threshold2) {
            _movement = '걷기';
          } else {
            _movement = '뛰기';
          }
        });
        controller.magnitudes.clear();
      }
    });
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.pets, size: 50, color: Colors.white),
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
                  ValueListenableBuilder<String>(
                    valueListenable: ValueNotifier(_movement),
                    builder: (context, movement, child) {
                      return Image.asset(
                        movement == '뛰기'
                            ? 'assets/running-dog-silhouette_47203.png'
                            : movement == '걷기'
                            ? 'assets/dog-facing-right.png'
                            : 'assets/sitting-dog-icon.png',  // 정지일 때도 기본 이미지
                        width: 24,
                        height: 24,
                      );
                    },
                  ),
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
                                subtitle: Text(data.device.id.id),
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