import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

  // 반응형 변수로 변경
  RxString completeData = "".obs;
  RxString bpmData = "74".obs;  // 초기값 설정
  RxString temperatureData = "36.5".obs;

  // 다른 클래스에서 사용할 수신한 전체 데이터 변수
  String get s_completeData => completeData.value;
  String get s_temperature => temperatureData.value;
  String get s_bpm => bpmData.value;

  var isScanning = false.obs;

  Rx<String?> connectingDeviceId = Rx<String?>(null);
  RxBool isConnected = false.obs;

  // 운동량 측정을 위한 리스트 추가
  RxList<double> magnitudes = <double>[].obs;

  DateTime lastUpdateTime = DateTime.now();

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
      connectingDeviceId.value = device.id.id;
      await device.connect(timeout: Duration(seconds: 15));
      connectedDevice = device;
      isConnected.value = true;
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
    }finally{
      connectingDeviceId.value = null;
    }
  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.value.listen((value) {
      String data = utf8.decode(value);
      print("Raw received data: $data");

      if (data.contains('V')) {  // 백슬래시를 포함한 데이터는 체온/심박수
        List<String> parts = data.split('|');
        print("Vital signs parts: $parts");
        try {
         String temperStr = temperatureData.value = parts[0].trim();
         double temperatureValue = double.parse(temperStr);
         double adjustTemperature = temperatureValue + 3.40;
         temperatureData.value = adjustTemperature.toStringAsFixed(1);
         print("Temperature updated: ${temperatureData.value}");

         // 심박수 처리 ('V' 제거하고 처리)
         String bpmStr = parts[1].replaceAll('V', '').trim();
         double bpmValue = double.parse(bpmStr);
         double adjustedBpm = bpmValue + 60.0;
         bpmData.value = adjustedBpm.toStringAsFixed(1);
         print("BPM updated: ${bpmData.value}");

        } catch (e) {
          print("Error processing temp/BPM data: $e");
        }
      } else if (data.contains('!')) {  // 자이로/가속도 데이터
        completeData.value += data;
        _processMotionData(completeData.value);
        completeData.value = "";
      } else {
        completeData.value += data;
        print("Accumulating data: ${completeData.value}");
      }
    });
  }

  void _processMotionData(String motionData) {
    List<String> dataParts = motionData.split('|');
    print("Processing motion data parts: $dataParts");

    if (dataParts.length >= 8) {
      try {
        double ax = double.tryParse(dataParts[2].trim()) ?? 0;
        double ay = double.tryParse(dataParts[3].trim()) ?? 0;
        double az = double.tryParse(dataParts[4].trim()) ?? 0;
        double gx = double.tryParse(dataParts[5].trim()) ?? 0;
        double gy = double.tryParse(dataParts[6].trim()) ?? 0;
        double gz = double.tryParse(dataParts[7].trim()) ?? 0;

        double magnitude = sqrt(ax * ax + ay * ay + az * az + gx * gx + gy * gy + gz * gz);

        if(magnitude > 0.1)
          {
            magnitudes.add(magnitude);
            lastUpdateTime = DateTime.now();
          }

        print("Calculated magnitude: $magnitude");

        if (magnitudes.length > 100) {
          magnitudes.removeAt(0);
        }
      } catch (e) {
        print("Error processing motion data: $e");
      }
    }
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
      List<int> byteArray = [0x01];
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