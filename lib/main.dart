import 'package:firstnote/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:async';

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
  double _threshold1 = 1.0; // 걷기 임계값
  double _threshold2 = 5.0; // 뛰기 임계값
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
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
            // Top Bar
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

            // Profile Section
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
                  Text(
                    _movement,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Section with BLE data
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
                        if (controller.receivedDataList.isNotEmpty) {
                          var lastData = controller.receivedDataList.last.split('|');
                          return Text(
                            '${lastData.length > 1 ? lastData[1] : "110"} bpm',
                            style: const TextStyle(fontSize: 16),
                          );
                        }
                        return Text('110 bpm', style: const TextStyle(fontSize: 16));
                      }),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Obx(() {
                        if (controller.receivedDataList.isNotEmpty) {
                          var lastData = controller.receivedDataList.last.split('|');
                          return Text(
                            '${lastData.isNotEmpty ? lastData[0] : "37"}°C',
                            style: const TextStyle(fontSize: 16),
                          );
                        }
                        return Text('37°C', style: const TextStyle(fontSize: 16));
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Device List from BLE
            Expanded(
              child: GetBuilder<BleController>(
                builder: (controller) {
                  return StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
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

            // Bottom Buttons
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
                    onPressed: () => controller.scanDevices(),
                    child: const Text('주변 기기 찾기'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => controller.sendData(1),
                    child: const Text('PET-EYE'),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar
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