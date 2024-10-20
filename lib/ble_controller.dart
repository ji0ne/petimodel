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

  // 이 클래스 안에서만 사용되는 private 변수
  String completeData = "";
  String bpmData ="";
  String temperatureData ="";

  // 다른 클래스에서 사용할 수신한 전체 데이터 변수
  String get s_completeData => completeData;
  String get s_temperature => temperatureData;
  String get s_bpm => bpmData;


  //var s_bpm = '74'.obs; // 초기 값으로 문자열 사용
  //var s_temperature = '36.5'.obs; // 초기 값으로 문자열 사용


  var isScanning = false.obs;

  // 운동량 측정을 위한 리스트 추가
  RxList<double> magnitudes = <double>[].obs;

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
        //_processData(completeData);
        List<String> dataParts = completeData.split('|');
        String bpm = dataParts[0].trim();
        String temperature = dataParts[1].trim();
        bpmData = bpm;
        temperatureData = temperature;
        print("s_bpm : $bpmData" );
        print("s_temp : $temperatureData");

        completeData = "";
      } else {
        completeData += data;
      }
      //
      // receivedDataList.add(data);
      // if (receivedDataList.length > 100) {
      //   receivedDataList.removeAt(0);
      // }
    });
  }

  void _processData(String completeData) {
    List<String> dataParts = completeData.split('|');

    if(dataParts.length >=2)
      {
        String bpm = dataParts[0].trim();
        String temperature = dataParts[1].trim();

        bpmData = bpm;
        temperatureData = temperature;

        print("s_bpm : $bpmData" );
        print("s_temp : $temperatureData");
      }

    if (dataParts.length >= 8) {
      double ax = double.tryParse(dataParts[2]) ?? 0;
      double ay = double.tryParse(dataParts[3]) ?? 0;
      double az = double.tryParse(dataParts[4]) ?? 0;
      double gx = double.tryParse(dataParts[5]) ?? 0;
      double gy = double.tryParse(dataParts[6]) ?? 0;
      double gz = double.tryParse(dataParts[7]) ?? 0;

      double magnitude = sqrt(ax * ax + ay * ay + az * az + gx * gx + gy * gy + gz * gz);
      magnitudes.add(magnitude);

      // magnitudes 리스트의 크기를 제한하여 메모리 사용을 관리합니다
      if (magnitudes.length > 100) {
        magnitudes.removeAt(0);
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