import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'ble_controller.dart';
import 'dart:typed_data';

class BehaviorPrediction {
  final BleController bleController = Get.find<BleController>();
  OrtEnv? env;
  OrtSession? session;
  List<int> predictionBuffer = [];
  final RxString predictedBehavior = '정지'.obs; // 예측된 행동 상태

  final Map<int, String> classLabels = {
    0: "질주",
    1: "엎드리기",
    2: "흔들기",
    3: "앉기",
    4: "서 있기",
    5: "속보",
    6: "걷기"
  };

  BehaviorPrediction() {
    _loadModel();
    _startPredictionLoop();
  }

  Future<void> _loadModel() async {
    try {
      env = OrtEnv.instance;

      // 'assets/wandb_model.onnx' 파일 로드
      final ByteData data = await rootBundle.load('assets/model/wandb_model.onnx');
      final buffer = data.buffer;

      // 임시 디렉토리에 ONNX 파일 저장
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/wandb_model.onnx';

      File modelFile = await File(tempPath).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      // ONNX 세션 초기화
      OrtSessionOptions options = OrtSessionOptions();
      session = OrtSession.fromFile(modelFile, options);

      print("ONNX 모델 로드 성공!");
    } catch (e) {
      print("ONNX 모델 로드 실패: $e");
    }
  }

  void _startPredictionLoop() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (session != null) {
        _predict();
      }
    });
  }

  void _predict() async {
    if (session == null) return;

    try {
      // BLE 컨트롤러에서 motionData를 가져와서 처리
      String motionData = bleController.s_completeData;
      List<String> dataParts = motionData.split('|');
      print("Processing motion data parts: $dataParts");

      if (dataParts.length >= 8) {
        double ax = double.tryParse(dataParts[2].trim()) ?? 0;
        double ay = double.tryParse(dataParts[3].trim()) ?? 0;
        double az = double.tryParse(dataParts[4].trim()) ?? 0;
        double gx = double.tryParse(dataParts[5].trim()) ?? 0;
        double gy = double.tryParse(dataParts[6].trim()) ?? 0;
        double gz = double.tryParse(dataParts[7].trim()) ?? 0;

        List<double> inputData = [ax, ay, az, gx, gy, gz];

        // 3차원 입력으로 변환
        Float32List inputTensorData = Float32List.fromList(inputData);
        OrtValueTensor inputTensor = OrtValueTensor.createTensorWithDataList(
            [inputTensorData],
            [1,inputData.length,1] // [batch_size, sequence_length, feature_dimension]
        );

        // 수정된 입력 및 출력 이름 사용
        final Map<String, OrtValue> input = {'conv1d_input': inputTensor};
        List<OrtValue?> outputs = session!.run(OrtRunOptions(), input, ['dense_1']);
        OrtValueTensor outputTensor = outputs.first as OrtValueTensor;
        List<double> output = (outputTensor.value as List<List<double>>).first;

        int predictedIndex = output.indexOf(output.reduce((a, b) => a > b ? a : b));
        predictionBuffer.add(predictedIndex);

        if (predictionBuffer.length >= 100) {
          Map<int, int> frequencyMap = {};
          for (var index in predictionBuffer) {
            frequencyMap[index] = (frequencyMap[index] ?? 0) + 1;
          }
          int mostFrequentIndex = frequencyMap.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          // 7가지 행동을 정지, 걷기, 뛰기로 분류
          if (mostFrequentIndex == 0 || mostFrequentIndex == 5) { // 질주 또는 속보
            predictedBehavior.value = '뛰기';
          } else if (mostFrequentIndex == 6) { // 걷기
            predictedBehavior.value = '걷기';
          } else { // 나머지 행동 (엎드리기, 흔들기, 앉기, 서 있기)
            predictedBehavior.value = '정지';
          }

          // 예측된 행동 상태 출력
          print("예측된 행동: ${predictedBehavior.value}");

          predictionBuffer.clear();
        }
      }
    } catch (e) {
      print("예측 오류: $e");
    }
  }
}
