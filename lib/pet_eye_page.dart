import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class PetEyePage extends StatefulWidget {
  const PetEyePage({Key? key}) : super(key: key);

  @override
  State<PetEyePage> createState() => _PetEyePageState();
}

class _PetEyePageState extends State<PetEyePage> {
  static const String baseUrl = 'http://devse.gonetis.com:12478';
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  String _mediaType = 'none';  // 'image', 'video', 'mjpeg', 'none'

  String _currentFileName = '';

  @override
  void initState() {
    super.initState();
    _checkLatestMedia();
  }

  Future<String> _getLatestFileName(String type) async {
    try {
      String endpoint = '';
      switch (type) {
        case 'image':
          endpoint = '/uploaded_jpeg';
          break;
        case 'video':
          endpoint = '/uploaded_mp4';
          break;
        case 'mjpeg':
          endpoint = '/uploaded_mjpeg';
          break;
      }

      final response = await http.head(Uri.parse('$baseUrl$endpoint'));
      // Content-Disposition 헤더에서 파일명 추출
      String? fileName = response.headers['content-disposition']?.split('filename=').last;
      return fileName ?? 'Unknown file';
    } catch (e) {
      print('Error getting filename: $e');
      return 'Error loading filename';
    }
  }

  Future<void> _checkLatestMedia() async {
    try {
      // 이미지 확인
      final imageResponse = await http.head(Uri.parse('$baseUrl/uploaded_jpeg'));
      if (imageResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'image';
          _currentFileName = imageResponse.headers['content-disposition']?.split('filename=').last ?? 'Unknown file';
        });
        return;
      }

      // 비디오 확인
      final videoResponse = await http.head(Uri.parse('$baseUrl/uploaded_mp4'));
      if (videoResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'video';
          _currentFileName = videoResponse.headers['content-disposition']?.split('filename=').last ?? 'Unknown file';
        });
        _initializeVideoPlayer();
        return;
      }

      // MJPEG 확인
      final mjpegResponse = await http.head(Uri.parse('$baseUrl/uploaded_mjpeg'));
      if (mjpegResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'mjpeg';
          _currentFileName = mjpegResponse.headers['content-disposition']?.split('filename=').last ?? 'Unknown file';
        });
        return;
      }
    } catch (e) {
      print('Error checking media: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network('$baseUrl/uploaded_mp4');
    try {
      await _videoController.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController.play();
      _videoController.setLooping(true);
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    if (_mediaType == 'video') {
      _videoController.dispose();
    }
    super.dispose();
  }

  Widget _buildMediaContent() {
    switch (_mediaType) {
      case 'image':
        return Image.network(
          '$baseUrl/uploaded_jpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('이미지를 불러올 수 없습니다'));
          },
        );

      case 'video':
        if (!_isVideoInitialized) {
          return Center(child: CircularProgressIndicator());
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        );

      case 'mjpeg':
        return Image.network(
          '$baseUrl/uploaded_mjpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          headers: {'Connection': 'keep-alive'},
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('스트림을 불러올 수 없습니다'));
          },
        );

      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 미디어 콘텐츠
          _buildMediaContent(),

          // 반투명 그라데이션 오버레이
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 상단 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // 파일명 추가
                    Text(
                      _getFileName(), // 현재 미디어 타입에 따른 파일명
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.folder, color: Colors.white),
                      onPressed: () {/* 폴더 기능 구현 */},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 정보 (기존과 동일)
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2024.07.11',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  '히로의 하루',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 파일명을 반환하는 메서드 추가
  String _getFileName() {
    switch (_mediaType) {
      case 'image':
        return 'uploaded_jpeg';
      case 'video':
        return 'uploaded_mp4';
      case 'mjpeg':
        return 'uploaded_mjpeg';
      default:
        return '';
    }
  }
}