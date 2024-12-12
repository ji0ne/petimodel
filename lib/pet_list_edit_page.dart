import 'package:flutter/material.dart';
import 'package:petimodel/pet_add_page.dart';
import 'mock_data.dart';

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

class PetListEditPage extends StatefulWidget {
  const PetListEditPage({super.key});

  @override
  State<PetListEditPage> createState() => _PetListEditPageState();
}

class _PetListEditPageState extends State<PetListEditPage> {
  List<Pet> pets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  void _loadPets() {
    // 임시로 Mock 데이터 사용
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        final mockData = MockPetData.data;
        pets = (mockData['list'] as List)
            .map((json) => Pet.fromJson(json as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });
    });
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'User 님의 아이들',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange))
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: pets.length + 1, // +1 for the add button
                    itemBuilder: (context, index) {
                      if (index < pets.length) {
                        final pet = pets[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: pet.profilePictureURL != null
                                          ? Image.network(
                                              pet.profilePictureURL!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
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
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Image.asset(
                                  'assets/x-icon.png',
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Add button
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PetAddPage()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/plus-icon.png',
                                width: 64,
                                height: 64,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle edit completion
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '수정완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
