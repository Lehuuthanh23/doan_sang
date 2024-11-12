import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_do_vui/model/bocauhoi.dart';
import 'package:game_do_vui/model/room.dart';
import 'package:game_do_vui/screen/room_information.dart';

class BoCauHoi extends StatefulWidget {
  final Map<String, dynamic> categories;
  const BoCauHoi({super.key, required this.categories});

  @override
  State<BoCauHoi> createState() => _BoCauHoiState();
}

class _BoCauHoiState extends State<BoCauHoi> {
  List<Map<String, dynamic>> categories = [];
  Future<void> fetchCategories() async {
    try {
      QuerySnapshot categorySnapshot =
          await FirebaseFirestore.instance.collection('chu_de').get();

      List<Map<String, dynamic>> fetchedCategories = categorySnapshot.docs
          .map((doc) => {
                'id': doc.id, // Add the document ID to the map
                ...doc.data() as Map<String, dynamic>, // Include other fields
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
        body: Stack(children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Padding( padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),),
                  const Text(
                    'Đối Kháng',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
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
                ...listBoCauHoi.map((cauhoi) =>
                    CustomCard(cauhoi: cauhoi, categories: widget.categories)),
              ],
            ),
          )
        ]),
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

      // Tạo một ID ngẫu nhiên gồm 6 chữ số
      String idRoom = _generateRandom6DigitId();

      Map<String, dynamic> roomData = {
        'id': idRoom,
        'password': pwController.text,
        'topicId': categories["id"],
        'users': [], // Thêm user vừa nhấn nút tạo phòng vào danh sách này
        'questionCount':
            "${cauhoi.quantity}", // Số lượng câu hỏi, có thể thiết lập tĩnh hoặc lấy từ dữ liệu
        'isStarted': false,
        'isPlaying': false,
      };
      room = Room.fromJson(roomData);
      try {
        // Tạo tài liệu mới với ID là số ngẫu nhiên 6 chữ số
        DocumentReference roomRef =
            FirebaseFirestore.instance.collection('rooms').doc(idRoom);

        await roomRef.set(roomData); // Thêm dữ liệu vào Firestore
        print("Room created with ID: $idRoom");

        // Thêm user hiện tại vào danh sách user trong room
        await roomRef.update({
          'users':
              FieldValue.arrayUnion([uid]) // thêm user ID của người nhấn nút
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
