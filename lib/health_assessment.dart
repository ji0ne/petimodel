import 'ble_controller.dart';

class HealthAssessment {
  final BleController controller;

  HealthAssessment(this.controller);

  // 건강 상태를 평가하는 메서드
  String assessHealth() {
    // 온도와 심박수를 가져오기
    double temperature = double.tryParse(controller.temperatureData.value) ?? 0.0;
    double heartRate = double.tryParse(controller.bpmData.value) ?? 0.0;
    String state = controller.behaviorPrediction.predictedBehavior.value;

    // 건강 상태를 평가하는 로직
    if (state == '정지') {
      if (temperature > 39.5 || heartRate > 110) return '위험';
      if (temperature > 39.2 || heartRate > 100) return '주의';
      return '정상';
    } else if (state == '걷기') {
      if (temperature > 40.0 || heartRate > 150) return '위험';
      if (temperature > 39.5 || heartRate > 140) return '주의';
      return '정상';
    } else if (state == '뛰기') {
      if (temperature > 40.5 || heartRate > 170) return '위험';
      if (temperature > 39.8 || heartRate > 160) return '주의';
      return '정상';
    }

    return '정보 부족'; // 예측 상태를 알 수 없을 때
  }
}
