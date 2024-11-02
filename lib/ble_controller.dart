import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'behavior_prediction.dart';
import 'package:onnxruntime/onnxruntime.dart';

class BleController extends GetxController {
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  RxList<String> receivedDataList = <String>[].obs;
  BluetoothCharacteristic? writeCharacteristic;

  // 반응형 변수로 변경
  RxString completeData = "".obs;
  RxString bpmData = "74".obs; // 초기값 설정
  RxString temperatureData = "36.5".obs;

  // 추가된 getter
  String get s_bpm => bpmData.value;
  String get s_temperature => temperatureData.value;

  // BLE 관련 상태 변수
  var isScanning = false.obs;
  Rx<String?> connectingDeviceId = Rx<String?>(null);
  RxBool isConnected = false.obs;
  DateTime lastUpdateTime = DateTime.now();

  // BehaviorPrediction 인스턴스
  late final BehaviorPrediction behaviorPrediction;

  // 생성자: BehaviorPrediction 인스턴스 생성
  BleController() {
    behaviorPrediction = BehaviorPrediction();
  }

  // 추가된 scanResults getter
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  void dispose() {
    connectedDevice?.disconnect();
    _deviceStateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanDevices() async {
    isScanning.value = true;
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    await Future.delayed(Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    isScanning.value = false;
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
    } finally {
      connectingDeviceId.value = null;
    }
  }

  StringBuffer _completeLog = StringBuffer();

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);

    // 가속도와 자이로 데이터를 각각 저장할 배열
    List<double> accelerometerData = [0, 0, 0];
    List<double> gyroscopeData = [0, 0, 0];
    List<List<double>> dataBuffer = [];

    _characteristicSubscription = characteristic.value.listen((value) {
      String data = utf8.decode(value);
      print("Raw received data: $data");

      _processReceivedPacket(data);

      if (data.contains('V')) {  // Vital signs data
        List<String> parts = data.split('|');
        try {
          String temperStr = parts[0].trim();
          double temperatureValue = double.parse(temperStr);
          double adjustTemperature = temperatureValue + 3.40;
          temperatureData.value = adjustTemperature.toStringAsFixed(1);

          String bpmStr = parts[1].replaceAll('V', '').trim();
          double bpmValue = double.parse(bpmStr);
          double adjustedBpm = bpmValue + 55.0;
          bpmData.value = adjustedBpm.toStringAsFixed(1);
        } catch (e) {
          print("Error processing temp/BPM data: $e");
        }
      }else if (data.endsWith('A')) {  // 가속도 데이터
        data = data.replaceAll('A', '');
        List<String> dataParts = data.split(',');

        if (dataParts.length == 3) {
          accelerometerData[0] = double.tryParse(dataParts[0].trim()) ?? 0;
          accelerometerData[1] = double.tryParse(dataParts[1].trim()) ?? 0;
          accelerometerData[2] = double.tryParse(dataParts[2].trim()) ?? 0;
        }
      }  else if (data.contains('!')) {  // Gyroscope data
        data = data.replaceAll('!', '');
        List<String> dataParts = data.split(',');

        if (dataParts.length == 3) {
          gyroscopeData[0] = double.tryParse(dataParts[0].trim()) ?? 0;
          gyroscopeData[1] = double.tryParse(dataParts[1].trim()) ?? 0;
          gyroscopeData[2] = double.tryParse(dataParts[2].trim()) ?? 0;

          // 자이로 데이터가 도착하면 한 세트의 데이터가 완성된 것으로 간주
          dataBuffer.add([...accelerometerData, ...gyroscopeData]);
          print("현재 버퍼 크기: ${dataBuffer.length}");

          if (dataBuffer.length >= 15) {
            _processDataBuffer(dataBuffer);
            dataBuffer.clear();
          }
        }
      }
    });
  }

  void _processReceivedPacket(String packet) {
    String timeStamp = DateTime.now().toString().substring(11, 19);

    // 패킷 종류별 처리
    if (packet.endsWith('V')) {  // 심박, 체온 데이터로 새로운 세트 시작
      _completeLog.clear();
      _completeLog.write(packet);
    }
    else if (packet.endsWith('A')) {  // 가속도 데이터 추가
      if (!_completeLog.isEmpty) {
        _completeLog.write(" | ");
        _completeLog.write(packet);
      }
    }
    else if (packet.endsWith('!')) {  // 자이로 데이터로 한 세트 완성
      if (!_completeLog.isEmpty) {
        _completeLog.write(" | ");
        _completeLog.write(packet);

        String completeData = _completeLog.toString();
        String formattedLog = "$timeStamp : $completeData";
        print("Complete data set: $completeData");
        receivedDataList.insert(0, formattedLog);
        _completeLog.clear();
      }
    }

    if (receivedDataList.length > 100) {
      receivedDataList.removeRange(80, receivedDataList.length);
    }
  }

  // 버퍼에 쌓인 데이터를 처리하는 메서드
  void _processDataBuffer(List<List<double>> dataBuffer) {
    for (var data in dataBuffer) {
      behaviorPrediction.processCompleteData(data);
    }
  }
}
