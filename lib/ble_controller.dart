import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  //데이터 로깅을 위한 변수들
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services =[];
  List<int> receivedData =[];
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  String completeData = "";

  @override
  void dispose()
  {
    connectedDevice?.disconnect();
    _deviceStateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }



  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {

      //10초간 스캔 진행
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
      await device.connect(timeout: Duration(seconds: 15));
      connectedDevice = device;
      print("기기 연결됨 : $connectedDevice ");


      services = await device.discoverServices();

      for(var service in services)
        {
          for(var characteristic in service.characteristics)
            {
              if(characteristic.uuid == Guid('00002a59-0000-1000-8000-00805f9b34fb'))
                {
                  if (characteristic.properties.notify) {
                    print("캐릭터 : $characteristic");
                    _subscribeToCharacteristic(characteristic);

                  }
                }
            }
        }
    } catch (e)
    {
      print("에러임....");
    }

  }

  int getByteCount(String str)
  {
    return utf8.encode(str).length;
  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic)
  {
    characteristic.setNotifyValue(true);
    _characteristicSubscription =
        characteristic.value.listen((value){
          String data = utf8.decode(value);
          print("Received data : $value");
          completeData += data;
         print("통문자열 : $completeData");
        });
  }

  Stream<List<ScanResult>> get scanResults => ble.scanResults;

  @override
  void onClose() {
    // 스트림 구독 해제
    _deviceStateSubscription?.cancel();
    super.onClose();
  }
}
