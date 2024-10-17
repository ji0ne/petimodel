import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  RxList<String> receivedDataList = <String>[].obs;
  BluetoothCharacteristic? writeCharacteristic;

  // 이 클래스 안에서만 사용되는 private 변수
  String completeData = "";

  // 다른 클래스에서 사용할 수신한 전체 데이터 변수
  String get s_completeData => completeData;

  var isScanning = false.obs;

  @override
  void dispose() {
    connectedDevice?.disconnect();
    _deviceStateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      isScanning.value = true;
      FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      await Future.delayed(Duration(seconds: 10));
      FlutterBluePlus.stopScan();
      isScanning.value = false;
    } else {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: Duration(seconds: 15));
      connectedDevice = device;
      print("기기 연결됨 : $connectedDevice");

      services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid('00002a57-0000-1000-8000-00805f9b34fb')) {
            if (characteristic.properties.notify) {
              print("Notify Characteristic Found: $characteristic");
              _subscribeToCharacteristic(characteristic);
            }
            if (characteristic.properties.write) {
              writeCharacteristic = characteristic;
              print("Write Characteristic Found: $writeCharacteristic");
            }
          }
        }
      }
    } catch (e) {
      print("Connection error: $e");
    }
  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.value.listen((value) {
      String data = utf8.decode(value);

      // 데이터 누적
      if (data.contains('!')) {
        completeData += data;
        print("Complete Data Received: $completeData");
        completeData = "";
      } else {
        completeData += data;
      }

      receivedDataList.add(data);
      if (receivedDataList.length > 100) {
        receivedDataList.removeAt(0);
      }
    });
  }

  Future<void> sendData(int number) async {
    if (number != 1) {
      print("Invalid number: Only 1 is supported");
      return;
    }

    if (connectedDevice == null) {
      print("No device connected");
      return;
    }

    if (writeCharacteristic == null) {
      print("Write characteristic not found");
      return;
    }

    try {
      // 0x01을 1바이트로 전송
      List<int> byteArray = [0x01];  // 16진수 0x01 사용

      await writeCharacteristic!.write(byteArray, withoutResponse: true);
      print('Data sent: 0x01');
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  void onClose() {
    _deviceStateSubscription?.cancel();
    super.onClose();
  }
}
