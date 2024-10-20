import 'package:flutter/material.dart';

class PetEyePage extends StatelessWidget {
  const PetEyePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 (여기서는 회색 배경으로 대체)
          Container(color: Colors.grey[300]),

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
                      icon: Icon(Icons.arrow_back, color: Colors.deepOrange),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.folder, color: Colors.deepOrange),
                      onPressed: () {/* 폴더 기능 구현 */},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 정보
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2024.07.11',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  '히로의 하루',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}