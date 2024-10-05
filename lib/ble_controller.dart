import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      ble.startScan(timeout: Duration(seconds: 10));

      // 스캔 종료 대기
      await Future.delayed(Duration(seconds: 10));
      ble.stopScan();
    } else {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // 이미 연결되어 있는지 확인
      var deviceState = await device.state.first;
      if (deviceState == BluetoothDeviceState.connected) {
        print("Already connected to ${device.name}");
        return;
      }

      // 장치 연결
      await device.connect(timeout: Duration(seconds: 15));

      // 상태 구독 시작
      _deviceStateSubscription?.cancel(); // 기존 구독 해제
      _deviceStateSubscription = device.state.listen((state) {
        if (state == BluetoothDeviceState.connected) {
          print("Device connected: ${device.name}");
        } else if (state == BluetoothDeviceState.disconnected) {
          print("Device disconnected");
        }
      });
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => ble.scanResults;

  @override
  void onClose() {
    // 스트림 구독 해제
    _deviceStateSubscription?.cancel();
    super.onClose();
  }
}
