import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  RxList<String> receivedDataList = <String>[].obs;

  String CompleteData = "";

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
      ble.startScan(timeout: Duration(seconds: 10));
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
      await device.connect(timeout: Duration(seconds: 15));
      connectedDevice = device;
      print("기기 연결됨 : $connectedDevice");

      services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid('00002a57-0000-1000-8000-00805f9b34fb')) {
            if (characteristic.properties.notify) {
              print("캐릭터 : $characteristic");
              _subscribeToCharacteristic(characteristic);
            }
          }
        }
      }
    } catch (e) {
      print("에러 발생: $e");
    }
  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.value.listen((value) {
      String data = utf8.decode(value);

      //누적
      if(data.contains('!'))
        {
          CompleteData += data;
          print("Complete Data Received! : $CompleteData");
          CompleteData = "";
        }else {
        CompleteData += data;
      }


      //print("Received data: $data");
      receivedDataList.add(data);
      if (receivedDataList.length > 100) {
        receivedDataList.removeAt(0);
      }
    });
  }

  Stream<List<ScanResult>> get scanResults => ble.scanResults;

  @override
  void onClose() {
    _deviceStateSubscription?.cancel();
    super.onClose();
  }
}