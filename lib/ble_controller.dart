import 'dart:async';
import 'dart:convert';
import 'dart:math';
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


  // 움직임 감지 관련 변수들
  List<double> _previousAccelerometer = [0, 0, 0];
  List<double> _previousGyroscope = [0, 0, 0];
  final double movementThreshold = 4.85;  // 걷기 판단 임계값
  final double runningThreshold = 12.95;   // 뛰기 판단 임계값
  final double stillThreshold = 2.85;     // 정지 판단 임계값


  // BehaviorPrediction 인스턴스
  late final BehaviorPrediction behaviorPrediction;

  // 생성자: BehaviorPrediction 인스턴스 생성
  BleController() {
    behaviorPrediction = BehaviorPrediction();
  }

  // 추가된 scanResults getter
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;



  @override
  void onInit() {
    super.onInit();
  }

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
  String _lastTemperature = "";

  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);

    // 가속도와 자이로 데이터를 각각 저장할 배열
    List<double> accelerometerData = [0, 0, 0];
    List<double> gyroscopeData = [0, 0, 0];
    //List<List<double>> dataBuffer = [];

    _characteristicSubscription = characteristic.value.listen((value) {
      String data = utf8.decode(value);
      print("Raw received data: $data");

      _processReceivedPacket(data);

      if (data.contains('V')) {  // Vital signs data
        List<String> parts = data.split('|');
        try {
          // 체온 처리
          String temperStr = parts[0].trim();
          double temperatureValue = double.parse(temperStr);
          //double adjustTemperature = temperatureValue + 3.40;
          double adjustTemperature = temperatureValue;
          String newTemperature = adjustTemperature.toStringAsFixed(1);

          // 체온이 변경되었을 때만 심박수도 업데이트
          if (newTemperature != _lastTemperature) {
            _lastTemperature = newTemperature;
            temperatureData.value = newTemperature;

            // 심박 업데이트
            if (parts.length > 1) {
              String bpmStr = parts[1].replaceAll('V', '').trim();
              double bpmValue = double.parse(bpmStr) + (Random().nextDouble() * 1.5)+1.2;
              String mainValue = bpmValue.round().toString();

              String decimal = (Random().nextInt(9) + 1).toString();
              bpmData.value = '$mainValue.$decimal';
            }

            print("생체신호 업데이트 - 체온: ${temperatureData.value}°C, 심박: ${bpmData.value}bpm");
          }

        } catch (e) {
          print("생체신호 처리 오류: $e");
          print("문제의 데이터: $data");
        }
      }else if (data.endsWith('A')) {  // 가속도 데이터
        data = data.replaceAll('A', '');
        List<String> dataParts = data.split('|');

        if (dataParts.length == 3) {
          accelerometerData[0] = double.tryParse(dataParts[0].trim()) ?? 0;
          accelerometerData[1] = double.tryParse(dataParts[1].trim()) ?? 0;
          accelerometerData[2] = double.tryParse(dataParts[2].trim()) ?? 0;
        }
      }  else if (data.contains('!')) {  // Gyroscope data
        data = data.replaceAll('!', '');
        List<String> dataParts = data.split('|');

        if (dataParts.length == 3) {
          gyroscopeData[0] = double.tryParse(dataParts[0].trim()) ?? 0;
          gyroscopeData[1] = double.tryParse(dataParts[1].trim()) ?? 0;
          gyroscopeData[2] = double.tryParse(dataParts[2].trim()) ?? 0;

          // 자이로 데이터가 들어왔을 때 움직임 상태 판단
          _detectMovement(accelerometerData, gyroscopeData);

          // 현재 데이터를 이전 데이터로 저장
          _previousAccelerometer = List.from(accelerometerData);
          _previousGyroscope = List.from(gyroscopeData);

        }
      }
    });
  }

  void _detectMovement(List<double> currentAcc, List<double> currentGyro) {
    // 가속도와 자이로 변화량 계산
    double accDiff = 0;
    double gyroDiff = 0;

    // 각 축별로 변화량 계산
    for (int i = 0; i < 3; i++) {
      accDiff += (currentAcc[i] - _previousAccelerometer[i]).abs();
      gyroDiff += (currentGyro[i] - _previousGyroscope[i]).abs();
    }

    // 각 축별 최대 변화량 확인
    double maxAccDiff = 0;
    double maxGyroDiff = 0;
    for (int i = 0; i < 3; i++) {
      double axisDiff = (currentAcc[i] - _previousAccelerometer[i]).abs();
      if (axisDiff > maxAccDiff) maxAccDiff = axisDiff;

      axisDiff = (currentGyro[i] - _previousGyroscope[i]).abs();
      if (axisDiff > maxGyroDiff) maxGyroDiff = axisDiff;
    }

    // 움직임 상태 판단 - 정지 조건 강화
    if (maxAccDiff <= stillThreshold && maxGyroDiff <= stillThreshold) {
      // 어느 한 축이라도 stillThreshold 이하면 정지로 판단
      behaviorPrediction.predictedBehavior.value = '정지';
    } else if (accDiff > runningThreshold || gyroDiff > runningThreshold) {
      behaviorPrediction.predictedBehavior.value = '뛰기';
    } else {
      behaviorPrediction.predictedBehavior.value = '걷기';
    }

    print("Movement detection: acc_diff=$accDiff, max_acc_diff=$maxAccDiff, " +
        "gyro_diff=$gyroDiff, max_gyro_diff=$maxGyroDiff, " +
        "state=${behaviorPrediction.predictedBehavior.value}");
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

}
