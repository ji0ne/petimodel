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

  Timer? _dataTimer;

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

      /*ble.scanResults.listen((results) {
        for (var result in results)
          {
              print('Device found: ${result.device.name}');
          }
      });*/

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

      services = await device.discoverServices();
      for(var service in services)
        {
          for(var characteristic in service.characteristics)
            {
              if(characteristic.uuid == Guid('00002a59-0000-1000-8000-00805f9b34fb'))
                {
                  if (characteristic.properties.notify) {
                    _subscribeToCharacteristic(characteristic);
                  }
                }
            }
        }
    } catch (e)
    {
      print('Error');
    }

  }

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic)
  {
    characteristic.setNotifyValue(true);
    _characteristicSubscription =
        characteristic.value.listen((value){
          String data = utf8.decode(value);
          print("Received data : $data");

          _parseGyroData(data);
        });
  }

  void _parseGyroData(String data)
  {
    if (data.contains("gyro=")) {
      var gyroData = data.split('|')[0].replaceAll("gyro=", "");
      print("Parsed Gyro Data: $gyroData");

      // x, y, z 값 추출
      var gyroValues = gyroData.split(',');
      var gyroX = gyroValues[0].split(':')[1].trim();
      var gyroY = gyroValues[1].split(':')[1].trim();
      var gyroZ = gyroValues[2].split(':')[1].trim();

      print("Gyro X: $gyroX, Gyro Y: $gyroY, Gyro Z: $gyroZ");
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
