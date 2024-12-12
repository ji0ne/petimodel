import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petimodel/pet_list_edit_page.dart';
import 'dart:convert';
import 'config.dart';
import 'package:intl/intl.dart';
import 'mock_data.dart';
import 'pet_main_page.dart';

class Pet {
  final int petId;
  final String name;
  final int gender;
  final String breed;
  final DateTime birth;
  final String? profilePictureURL;

  Pet({
    required this.petId,
    required this.name,
    required this.gender,
    required this.breed,
    required this.birth,
    this.profilePictureURL,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      petId: json['petId'],
      name: json['name'],
      gender: json['gender'],
      breed: json['breed'],
      birth: DateTime.parse(json['birth']),
      profilePictureURL: json['profilePictureURL'],
    );
  }
}

class PetListPage extends StatefulWidget {
  const PetListPage({super.key});

  @override
  State<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  List<Pet> pets = [];
  bool isLoading = true;
  String userName = '';

  @override
  void initState() {
    super.initState();
    // _fetchPets();
    _loadMockData();
  }

  void _loadMockData() {
    // 잠시 로딩 효과를 주기 위해 약간의 딜레이 추가
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        final mockData = MockPetData.data;
        pets = (mockData['list'] as List)
            .map((json) => Pet.fromJson(json))
            .toList();
        userName = MockPetData.userName;
        isLoading = false;
      });
    });
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchPets() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.getServerURL()}/pets'),
        headers: {
          'Content-Type': 'application/json',
          // 필요한 경우 인증 토큰 추가
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> petsJson = json.decode(response.body);
        setState(() {
          pets = petsJson.map((json) => Pet.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pets');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching pets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'User 님의 아이들',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/edit-icon.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PetListEditPage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetMainPage(pet: pet),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 0,
                            ),
                          ),
                          child: ClipOval(
                            child: pet.profilePictureURL != null
                                ? Image.network(
                                    pet.profilePictureURL!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFFFF0E5),
                                        child: const Icon(
                                          Icons.pets,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.pets,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pet.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatBirthDate(pet.birth),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
