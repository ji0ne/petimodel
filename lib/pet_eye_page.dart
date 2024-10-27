import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:firstnote/pet_eye_album_page.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLatestMedia();
  }

  Future<void> _checkLatestMedia() async {
    try {
      final imageResponse = await http.head(Uri.parse('$baseUrl/static/images/uploaded_jpeg'));
      if (imageResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'image';
        });
        return;
      }

      final videoResponse = await http.head(Uri.parse('$baseUrl/static/images/uploaded_mp4'));
      if (videoResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'video';
        });
        _initializeVideoPlayer();
        return;
      }

      final mjpegResponse = await http.head(Uri.parse('$baseUrl/static/images/uploaded_mjpeg'));
      if (mjpegResponse.statusCode == 200) {
        setState(() {
          _mediaType = 'mjpeg';
        });
        return;
      }
    } catch (e) {
      print('Error checking media: $e');
      _showErrorSnackbar('Error checking media');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network('$baseUrl/static/images/uploaded_mp4');
    try {
      await _videoController.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController.play();
      _videoController.setLooping(true);
    } catch (e) {
      print('Error initializing video: $e');
      _showErrorSnackbar('Error loading video');
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
          '$baseUrl/static/images/uploaded_jpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Image load error: $error');
            _showErrorSnackbar('Error loading image');
            return Center(child: Text('이미지를 불러올 수 없습니다'));
          },
        );

      case 'video':
        if (!_isVideoInitialized) {
          return Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_videoController.value.isPlaying) {
                          _videoController.pause();
                        } else {
                          _videoController.play();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      // 볼륨 조절 기능 추가
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      // 전체 화면 모드 전환 기능 추가
                    },
                  ),
                ],
              ),
            ),
          ],
        );

      case 'mjpeg':
        return Image.network(
          '$baseUrl/static/images/uploaded_mjpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          headers: {'Connection': 'keep-alive'},
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            print('MJPEG load error: $error');
            _showErrorSnackbar('Error loading MJPEG stream');
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
          _buildMediaContent(),
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
                    IconButton(
                      icon: Icon(Icons.folder, color: Colors.white),
                      onPressed: () {
                        print("폴더 아이콘 클릭됨");
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PetEyeAlbumPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}