import 'dart:io' show Platform;

class Config {
  // static const String _androidServer = 'http://10.0.2.2:5500';
  static const String _androidServer = 'http://180.81.130.195:8000';
  static const String _iosServer = 'http://localhost:5500';
  static const String _server = 'http://freeptk.iptime.org:5500';

  static String getServerURL() {
    if (Platform.isIOS) {
      return _iosServer;
    } else if (Platform.isAndroid) {
      return _androidServer;
    } else {
      throw UnsupportedError('iOS 또는 Android만 지원됩니다.');
    }
  }
}
