import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/model/room.dart';
import 'package:game_do_vui/screen/play_one.dart';
import 'package:game_do_vui/screen/question_set_selection.dart';
import 'package:game_do_vui/screen/room_information.dart';
import 'package:game_do_vui/screen/topic.dart';
import 'package:game_do_vui/screen/topic_selection.dart';

class GameMode extends StatefulWidget {
  const GameMode({super.key});

  @override
  State<GameMode> createState() => _GameModeState();
}

class _GameModeState extends State<GameMode> {
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

  Future<void> joinRoom(String roomId, String notificationId) async {
    DocumentSnapshot roomSnapshot =
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();

    if (roomSnapshot.exists) {
      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;

      Room room = Room(
        id: roomId,
        password: roomData['password'],
        questionCount: roomData['questionCount'],
        users: List<String>.from(roomData['users']),
        topicId: roomData['topicId'],
        isStarted: roomData['isStarted'],
        isPlaying: roomData["isPlaying"],
      );
      Map<String, dynamic> categoryData = categories.firstWhere(
        (category) {
          print('Alo ${category}');
          return category['id'] == room.topicId;
        },
        orElse: () => {'title': 'Unknown'},
      );

      // Navigate to RoomInformation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ThongTinPhong(room: room, categories: categoryData),
        ),
      );

      // Delete notification after joining
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } else {
      print('Room not found.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room not found.')),
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
    print('Notification $notificationId deleted');
  }

  void _findRoom(BuildContext context) {
    TextEditingController roomIdController =
        TextEditingController(); // Để lấy ID phòng nhập vào
    TextEditingController pwController =
        TextEditingController(); // Để lấy ID phòng nhập vào

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tìm phòng'),
          content: Container(
            height: 120,
            child: Column(
              children: [
                TextField(
                  controller:
                      roomIdController, // Liên kết với TextEditingController
                  decoration: InputDecoration(
                    hintText: 'Nhập ID phòng',
                  ),
                  keyboardType: TextInputType.number, // Chỉ cho phép nhập số
                ),
                TextField(
                  controller:
                      pwController, // Liên kết với TextEditingController
                  decoration: InputDecoration(
                    hintText: 'Nhập pass phòng',
                  ),
                  keyboardType: TextInputType.text, // Chỉ cho phép nhập số
                ),
              ],
            ),
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
                String roomId = roomIdController.text;
                String pw = pwController.text;
                print('Tìm kiếm phòng với ID: $roomId');
                DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .get();
                if (roomSnapshot.exists) {
                  // Nếu tìm thấy phòng, kiểm tra mật khẩu
                  Map<String, dynamic> roomData =
                      roomSnapshot.data() as Map<String, dynamic>;

                  if (roomData['password'] == pw) {
                    // Mật khẩu đúng, in ra các giá trị trong phòng
                    print('Thông tin phòng:');
                    print('Mật khẩu: ${roomData['password']}');
                    print('ID chủ đề: ${roomData['topicId']}');
                    print('Số lượng câu hỏi: ${roomData['questionCount']}');
                    print('Danh sách người dùng: ${roomData['users']}');

                    String userId = FirebaseAuth.instance.currentUser!.uid;

                    // Thêm người dùng vào danh sách `users`
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .update({
                      'users': FieldValue.arrayUnion([userId]),
                    });
                    print('Người dùng $userId đã được thêm vào phòng $roomId');
                    Room room = Room(
                      id: roomId,
                      password: roomData['password'],
                      questionCount: roomData['questionCount'],
                      users: List<String>.from(roomData['users']),
                      topicId: roomData['topicId'],
                      isStarted: roomData['isStarted'],
                      isPlaying: roomData["isPlaying"],
                    );
                    Map<String, dynamic> categoryData = categories.firstWhere(
                      (category) {
                        print('Alo ${category}');
                        return category['id'] == room.topicId;
                      },
                      orElse: () => {'title': 'Unknown'},
                    );
                    print('alo ${categories}');
                    Navigator.of(context)
                        .pop(); // Đóng hộp thoại sau khi tìm kiếm
                    // Đóng hộp thoại sau khi tìm kiếm
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThongTinPhong(
                          room: room,
                          categories: categoryData,
                        ),
                      ),
                    );
                  } else {
                    // Mật khẩu sai
                    print('Sai mật khẩu.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sai mật khẩu.')),
                    );
                  }
                } else {
                  // Nếu không tìm thấy phòng
                  print('Phòng với ID $roomId không tồn tại.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Phòng với ID $roomId không tồn tại.')),
                  );
                }
              },
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    //fetchUserData();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/Background.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    const Text(
                      'Chế Độ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.white),
                    ),
                    IconButton(
                        icon: const Icon(
                          Icons.screen_search_desktop_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          _findRoom(context);
                        })
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                TopicSelectionScreen()), // Điều hướng đến trang chế độ
                      );
                    },
                    child: Text(
                      'Tự Luyện',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 150),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Chude()), // Điều hướng đến trang chế độ
                      );
                    },
                    child: Text(
                      'Đối Kháng',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
