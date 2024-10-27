// pet_eye_page.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';  // 비디오 재생을 위해 추가
import 'package:get/get.dart';

class PetEyePage extends StatefulWidget {
  @override
  _PetEyePageState createState() => _PetEyePageState();
}

class _PetEyePageState extends State<PetEyePage> {
  static const String baseUrl = 'http://devse.gonetis.com:12478';
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
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
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PET-EYE'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // 새로고침 로직
              setState(() {
                _initializeVideoPlayer();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 최근 이미지 표시
            Container(
              height: 200,
              width: double.infinity,
              margin: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '$baseUrl/uploaded_jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text('No recent image'));
                  },
                ),
              ),
            ),

            // 최근 비디오 표시
            Container(
              height: 200,
              width: double.infinity,
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: _isVideoInitialized
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
                  : Center(child: CircularProgressIndicator()),
            ),

            // MJPEG 스트림 표시
            Container(
              height: 200,
              width: double.infinity,
              margin: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '$baseUrl/uploaded_mjpeg',
                  fit: BoxFit.cover,
                  headers: {'Connection': 'keep-alive'},
                  gaplessPlayback: true,  // MJPEG 스트리밍을 위한 설정
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text('No MJPEG stream available'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}