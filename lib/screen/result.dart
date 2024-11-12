import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_do_vui/screen/play_history.dart';
import 'package:game_do_vui/setting/button.dart';

class ResultScreen extends StatefulWidget {
  final int correctAnswers;
  final double totalScore;
  final int totalQuestions; 
  final Duration playDuration;
  final String topicName;
  final List<Map<String, dynamic>> selectedAnswers;

  const ResultScreen({
    Key? key,
    required this.correctAnswers,
    required this.totalScore,
    required this.totalQuestions, 
    required this.playDuration,
    required this.topicName,
    required this.selectedAnswers
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String username = 'Loading...';
  String email = 'Chưa có email';
  String profileImageUrl = 'assets/default_avatar.png';

  @override
  void initState() {
    super.initState();
    fetchUserData();
    savePlayHistory();
  }

  Future<void> fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            username = userData['username'] ?? 'Chưa có tên người dùng';
            email = userData['email'] ?? 'Chưa có email';
            profileImageUrl = userData['profile_image'] ?? 'assets/default_avatar.png';
          });
        }
      } else {
        throw Exception('Không tìm thấy dữ liệu người dùng.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lấy dữ liệu người dùng: $e')),
      );
    }
  }

  Future<void> savePlayHistory() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Map<String, dynamic> playData = {
        'userId': uid,
        'topic': widget.topicName, 
        'questionSet': widget.totalQuestions, 
        'score': widget.totalScore,
        'playDuration': '${widget.playDuration.inMinutes} phút ${widget.playDuration.inSeconds.remainder(60)} giây',
        'mode': 'Chơi tự luyện',
        'completionTime': DateTime.now(),
      };

      print('Saving play history data: $playData'); 

      await FirebaseFirestore.instance.collection('playHistory').add(playData);
    } catch (e) {
      print('Lỗi khi lưu lịch sử chơi: $e');
    }
  }

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    'Kết quả',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlayHistoryScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.history, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 15,
            right: 15,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20,right: 20,bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                            radius: 50,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(fontSize: 22),
                              ),
                              Text(
                                email,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text('Chủ đề: ${widget.topicName}', style: const TextStyle(fontSize: 22)),
                      Text('Số câu hỏi: ${widget.totalQuestions}', style: const TextStyle(fontSize: 22)),
                      Text('Số câu đúng: ${widget.correctAnswers}', style: const TextStyle(fontSize: 22)),
                      Text('Điểm tổng: ${widget.totalScore.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22)),
                      Text('Thời gian chơi: ${widget.playDuration.inMinutes} phút ${widget.playDuration.inSeconds.remainder(60)} giây', style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      Text(
                        'Chi tiết câu trả lời:',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.selectedAnswers.length,
                        itemBuilder: (context, index) {
                          final answerData = widget.selectedAnswers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Câu ${index + 1}: ${answerData['question']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Đáp án đúng: ${answerData['correctAnswer']}',
                                    style: const TextStyle(fontSize: 16, color: Colors.green),
                                  ),
                                  Text(
                                    'Đáp án đã chọn: ${answerData['selectedAnswer']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: answerData['selectedAnswer'] == answerData['correctAnswer']
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: MyButton(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận thoát'),
                                content: const Text('Bạn có chắc chắn muốn thoát không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/homeuser');
                                    },
                                    child: const Text('Thoát'),
                                  ),
                                ],
                              ),
                            );
                          },
                          text: 'Kết thúc',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
