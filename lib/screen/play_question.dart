import 'dart:async';
import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_do_vui/model/room.dart';
import 'package:game_do_vui/screen/home_user.dart';
import 'package:game_do_vui/screen/result.dart';
import 'package:game_do_vui/screen/result_solo.dart';

class PlayQuestion extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> categories;
  final String questionCount;
  final Room room;
  final List<String> users;

  const PlayQuestion(
      {super.key,
      required this.topicId,
      required this.categories,
      required this.questionCount,
      required this.room,
      required this.users});

  @override
  State<PlayQuestion> createState() => _PlayQuestionState();
}

class _PlayQuestionState extends State<PlayQuestion> {
  int timeLeft = 15; // Thời gian cho mỗi câu
  Timer? timer;
  late DateTime startTime;
  int currentQuestionIndex = 0;
  int correctAnswersCount = 0;
  List<QueryDocumentSnapshot> questions = [];
  List<Map<String, dynamic>> selectedAnswers = [];
  String questionText = "";
  List<String> answers = [];
  String correctAnswer = "";
  double totalPoint = 0;
  DocumentReference? notiRef;
  StreamSubscription<DocumentSnapshot>? roomSubscription;
  bool showAwait = false;
  List<String> questionStatus =
      []; // Trạng thái của mỗi câu hỏi (xám, xanh, đỏ)
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    roomSubscription!.cancel();
  }

  @override
  void initState() {
    super.initState();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    notiRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.room.id);
    roomSubscription = notiRef!.snapshots().listen((snapshot) async {
      print('Vào lắng nghe điểm');
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        // Lấy danh sách các key có kết thúc bằng '_point'
        List<String> allPointsKeys = data.keys.where((key) {
          return key.endsWith('_point');
        }).toList();
        bool hasOtherUserPoint = data.keys.any((key) {
          return key.endsWith('_point') && !key.startsWith(currentUserId);
        });
        bool hasCurrentUserPoint = data.keys.any((key) {
          return key.endsWith('_point') && key.startsWith(currentUserId);
        });
        List<String> otherUserPoints = data.keys.where((key) {
          return key.endsWith('_point') && !key.startsWith(currentUserId);
        }).toList();

        if (hasOtherUserPoint) {
          // Hiển thị thông báo nếu có key kết thúc với _point nhưng không bắt đầu bằng currentUserId
          print("Có một bản ghi điểm từ người dùng khác.");
          double pointCurrentUser =
              double.parse(data['${currentUserId}_point']);
          double pointOtherUser =
              double.parse(data["${otherUserPoints.first}"]);
          int status = 0;
          if (pointCurrentUser > pointOtherUser) {
            status = 1;
          } else {
            status = 2;
          }
          // Xóa các trường có key kết thúc bằng '_point' mà không bắt đầu bằng `currentUserId`
          Map<String, dynamic> fieldsToDelete = {
            for (var key in allPointsKeys) key: FieldValue.delete()
          };
          await FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.room.id)
              .update(fieldsToDelete);
          await savePlayHistory();
          showResultSoloDialog(
            context,
            status,
            widget.room,
            showAwait,
            widget.categories,
          );
          // Thay thế bằng logic thông báo của bạn
        } else if (hasCurrentUserPoint) {
          print('Vào đợi');
          showAwait = true;
          showResultSoloDialog(
              context, 0, widget.room, showAwait, widget.categories);
        }
      }
    });
    fetchQuestions(); // Lấy câu hỏi từ Firestore
  }

  void startTimer() {
    timer?.cancel(); // Hủy bộ đếm trước đó nếu có
    setState(() {
      timeLeft = 15; // Đặt lại thời gian cho câu hỏi mới
    });
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        t.cancel();
        markQuestionAsTimedOut(); // Đánh dấu câu này là hết thời gian
      }
    });
  }

  void markQuestionAsTimedOut() {
    setState(() {
      questionStatus[currentQuestionIndex] =
          "timed_out"; // Đánh dấu câu này là hết thời gian
    });
    currentQuestionIndex++;
    loadQuestion(); // Tải câu hỏi tiếp theo
  }

  Future<void> fetchQuestions() async {
    int questionLimit = int.tryParse(widget.questionCount) ?? 10;
    var questionsSnapshot = await FirebaseFirestore.instance
        .collection('cau_hoi')
        .where('chu_de_id', isEqualTo: widget.topicId) // Lọc theo topicId
        .limit(questionLimit) // Giới hạn số lượng câu hỏi
        .get();

    setState(() {
      questions = questionsSnapshot.docs;
      questionStatus = List<String>.filled(questions.length, "unanswered");
    });
    loadQuestion(); // Tải câu hỏi đầu tiên
  }

  void loadQuestion() {
    if (currentQuestionIndex < questions.length) {
      var questionData =
          questions[currentQuestionIndex].data() as Map<String, dynamic>;

      setState(() {
        questionText = questionData['cau_hoi_text'];
        correctAnswer = questionData['cau_tra_loi_dung'];
        answers = List<String>.from(questionData['dap_an_sai']);
        answers.add(correctAnswer);
        answers.shuffle();
      });
      startTimer(); // Khởi động bộ đếm cho câu hỏi mới
    } else {
      showResuilt(context: context); // Hiển thị kết quả khi trả lời hết câu hỏi
    }
  }

  void showResuilt({bool timeOut = false, required BuildContext context}) {
    AwesomeDialog(
      dismissOnTouchOutside: false,
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      title: timeOut ? 'Hết thời gian' : 'Kết quả',
      desc:
          "Bạn đã trả lời đúng $correctAnswersCount trên ${questions.length} câu. Điểm của bạn là: ${totalPoint.toStringAsFixed(1)}",
      btnOkOnPress: () async {
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .update({
          'isPlaying': false,
        });
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .update({
          '${currentUserId}_point': "${totalPoint}",
        });

        // Navigator.of(context).pop(); // Đóng dialog
        // Navigator.of(context).pop();
      },
    )..show();
  }

  Future<void> onAnswerSelected(String selectedAnswer) async {
    timer?.cancel(); // Dừng bộ đếm khi chọn đáp án
    setState(() {
      questionStatus[currentQuestionIndex] =
          "answered"; // Đánh dấu câu này là đã trả lời
    });
    if (selectedAnswer == correctAnswer) {
      correctAnswersCount++;
      totalPoint += 10 + (timeLeft * 0.1);
    }
    currentQuestionIndex++;
    loadQuestion(); // Tải câu hỏi tiếp theo
  }

  Future<void> savePlayHistory() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      int inMinutes = (timeLeft / 60).floor();
      int inSeconds = timeLeft - (inMinutes * 60);
      Map<String, dynamic> playData = {
        'userId': uid,
        'topic': widget.categories["title"],
        'questionSet': widget.questionCount,
        'score': totalPoint,
        'playDuration': '${inMinutes} phút ${inSeconds} giây',
        'mode': 'Chơi đối kháng',
        'completionTime': DateTime.now(),
      };

      print('Saving play history data: $playData');

      await FirebaseFirestore.instance.collection('playHistory').add(playData);
    } catch (e) {
      print('Lỗi khi lưu lịch sử chơi: $e');
    }
  }

  void showResults({bool timeOut = false}) {
    Duration playDuration = DateTime.now().difference(startTime);
    timer?.cancel();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(timeOut ? "Hết thời gian!" : "Kết quả"),
        content: Text(
            "Bạn đã trả lời đúng $correctAnswersCount trên ${questions.length} câu. / Điểm của bạn là: ${totalPoint}"),
        actions: [
          TextButton(
            onPressed: () async {
              String currentUserId = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.room.id)
                  .update({
                '${currentUserId}_point': "${totalPoint}",
              });
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(
              //     builder: (context) => ResultScreen(
              //       correctAnswers: correctAnswersCount,
              //       totalScore: totalPoint,
              //       totalQuestions: questions.length,
              //       playDuration: playDuration,
              //       topicName: widget.topicId,
              //       selectedAnswers: selectedAnswers,
              //     ),
              //   ),
              //   (Route<dynamic> route) =>
              //       false, // Xóa tất cả các màn hình trước đó trong ngăn xếp
              // );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // @override
  // void dispose() {
  //   timer?.cancel(); // Hủy bộ đếm khi không cần thiết
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    int questionCount = questions.length;
    int rowLimit = (MediaQuery.of(context).size.width / 40).floor();
    List<Widget> indicators = List.generate(questionCount, (index) {
      Color indicatorColor;
      if (questionStatus[index] == "answered") {
        indicatorColor = Colors.green; // Đã trả lời (màu xanh)
      } else if (questionStatus[index] == "timed_out") {
        indicatorColor = Colors.red; // Hết thời gian (màu đỏ)
      } else {
        indicatorColor = Colors.grey; // Chưa làm (màu xám)
      }

      return Container(
        margin: EdgeInsets.all(4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    });

    List<Widget> rows = [];
    for (int i = 0; i < indicators.length; i += rowLimit) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            indicators.sublist(i, (i + rowLimit).clamp(0, indicators.length)),
      ));
    }

    void _closeRoom(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Thông Báo'),
            content: Container(
              height: 20,
              child: Column(
                children: [Text('Bạn muốn thoát đúng không?')],
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
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng hộp thoại
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeUsers()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Hình nền
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/Background2.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Thanh chỉ báo câu hỏi và thời gian
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        // Hiển thị chỉ báo câu hỏi
                        ...rows,
                        SizedBox(height: 10),
                        Text(
                          "Thời gian còn lại: $timeLeft giây",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Nút đóng
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    _closeRoom(context);
                  },
                ),
              ),
            ),
            // Hiển thị câu hỏi và đáp án
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    margin:
                        EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          questionText,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Nút chọn đáp án
                  for (String answer in answers)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => onAnswerSelected(answer),
                        child: Text(
                          answer,
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
