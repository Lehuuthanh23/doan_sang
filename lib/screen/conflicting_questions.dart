import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/model/room.dart';

import '../model/bocauhoi.dart';
import 'room_information.dart';

class ConflictingQuestions extends StatefulWidget {
  const ConflictingQuestions({super.key, required this.categories});
  final Map<String, dynamic> categories;

  @override
  State<ConflictingQuestions> createState() => _ConflictingQuestionsState();
}

class _ConflictingQuestionsState extends State<ConflictingQuestions> {
  List<Map<String, dynamic>> categories = [];
  Future<void> fetchCategories() async {
    try {
      QuerySnapshot categorySnapshot =
          await FirebaseFirestore.instance.collection('chu_de').get();

      List<Map<String, dynamic>> fetchedCategories = categorySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    List<Bocauhoi> listBoCauHoi = [
      Bocauhoi(id: 1, quantity: 10, title: 'Bộ 10 câu'),
      Bocauhoi(id: 1, quantity: 20, title: 'Bộ 20 câu'),
      Bocauhoi(id: 1, quantity: 30, title: 'Bộ 30 câu'),
    ];
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/Background2.jpg'),
                      fit: BoxFit.cover),
                ),
              ),
            ),
            Column(
              children: [
                AppBar(
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      size: 40,
                    ),
                  ),
                  title: Text(
                    widget.categories['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 35,
                    ),
                  ),
                  centerTitle: true,
                ),
              ],
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                      child: Text(
                    "Bộ Câu Hỏi",
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.w600),
                  )),
                  const SizedBox(
                    height: 50,
                  ),
                  ...listBoCauHoi.map((cauhoi) => CustomCard(
                      cauhoi: cauhoi, categories: widget.categories)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  CustomCard({
    super.key,
    required this.cauhoi,
    required this.categories,
  });
  Bocauhoi cauhoi;
  Map<String, dynamic> categories;
  TextEditingController pwController = TextEditingController();
  Room? room;
  Future<void> playRoom() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String idRoom = _generateRandom6DigitId();

      Map<String, dynamic> roomData = {
        'id': idRoom,
        'password': pwController.text,
        'topicId': categories["id"],
        'users': [],
        'questionCount': "${cauhoi.quantity}",
        'isStarted': false,
        'isPlaying': false,
      };
      room = Room.fromJson(roomData);
      try {
        DocumentReference roomRef =
            FirebaseFirestore.instance.collection('rooms').doc(idRoom);

        await roomRef.set(roomData);
        print("Room created with ID: $idRoom");
        await roomRef.update({
          'users': FieldValue.arrayUnion([uid])
        });
      } catch (e) {
        print("Error creating room: $e");
      }
      print('Room created successfully with ID: $idRoom');
    } catch (e) {
      print('Error creating room: $e');
    }
  }

// Hàm tạo ID ngẫu nhiên 6 chữ số
  String _generateRandom6DigitId() {
    Random random = Random();
    int randomNumber =
        random.nextInt(900000) + 100000; // Tạo số trong khoảng 100000-999999
    return randomNumber.toString();
  }

  void addRoonm(BuildContext context) {
// Để lấy ID phòng nhập vào

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tạo phòng'),
          content: TextField(
            controller: pwController, // Liên kết với TextEditingController
            decoration: InputDecoration(
              hintText: 'Nhập password phòng',
            ),
            keyboardType: TextInputType.visiblePassword, // Chỉ cho phép nhập số
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại
              },
              child: Text('Hủy bỏ'),
            ),
            TextButton(
              onPressed: () async {
                if (pwController.text.isEmpty) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Vui lòng nhập password'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Đóng hộp thoại
                                },
                                child: Center(child: Text('Ok')))
                          ],
                        );
                      });
                } else {
                  await playRoom();
                  pwController.clear();
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ThongTinPhong(
                              room: room!,
                              categories: categories,
                            )), // Điều hướng đến trang chế độ
                  );
                }
                // Đóng hộp thoại
              },
              child: Text('Tạo phòng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: () {
          addRoonm(context);
        },
        child: Text(
          cauhoi.title,
          style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
