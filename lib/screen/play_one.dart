import 'dart:math';
import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/result.dart';
import 'package:game_do_vui/service/question_service.dart';
import 'dart:async';

class PlayOneScreen extends StatefulWidget {
  final String chuDeId;
  final int questionCount;

  const PlayOneScreen(
      {Key? key, required this.chuDeId, required this.questionCount})
      : super(key: key);

  @override
  _PlayOneScreenState createState() => _PlayOneScreenState();
}

class _PlayOneScreenState extends State<PlayOneScreen> {
  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> selectedAnswers = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  double totalScore = 0;
  bool isLoading = true;
  int timeLeft = 30;
  late Timer timer;
  int questionCount = 0;
  late DateTime startTime;
  String topicName = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
    startTime = DateTime.now();
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        _nextQuestion();
      }
    });
  }

  Future<void> _loadQuestions() async {
    final questionService = QuestionService();
    questions = await questionService.fetchQuestions(
        widget.chuDeId, widget.questionCount);

    topicName = await questionService.fetchTopicName(widget.chuDeId);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không có câu hỏi nào cho chủ đề này.')));
      Navigator.of(context).pop();
      return;
    }

    final random = Random();
    for (var question in questions) {
      final correctAnswer = question['cau_tra_loi_dung'];
      final answers = List<String>.from(question['dap_an_sai']);
      answers.add(correctAnswer);
      answers.shuffle(random);
      question['all_answers'] = answers;
    }

    setState(() {
      isLoading = false;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timeLeft = 30;
      });
    } else {
      timer.cancel();
      _showResultScreen();
    }
  }

  void _checkAnswer(String selectedAnswer) {
    final correctAnswer = questions[currentQuestionIndex]['cau_tra_loi_dung'];

    selectedAnswers.add({
      'question': questions[currentQuestionIndex]['cau_hoi_text'],
      'correctAnswer': correctAnswer,
      'selectedAnswer': selectedAnswer,
    });

    if (selectedAnswer == correctAnswer) {
      correctAnswers++;
      totalScore += 10 + (timeLeft * 0.1);
    }
    _nextQuestion();
  }

  void _showResultScreen() {
    Duration playDuration = DateTime.now().difference(startTime);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          correctAnswers: correctAnswers,
          totalScore: totalScore,
          totalQuestions: widget.questionCount,
          playDuration: playDuration,
          topicName: topicName,
          selectedAnswers: selectedAnswers, 
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentQuestionIndex];
    final answers = question['all_answers'];

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        'Play In Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ],
            ),
            Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4.0,
                      runSpacing: 8.0,
                      children: List.generate(widget.questionCount, (index) {
                        return CircleAvatar(
                          backgroundColor: index < currentQuestionIndex
                              ? Colors.green
                              : (index == currentQuestionIndex
                                  ? Colors.red
                                  : Colors.grey),
                          radius: 12,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Thời gian còn lại: $timeLeft giây',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          question['cau_hoi_text'],
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ...List.generate(
                      answers.length,
                      (index) {
                        final option = answers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: BorderSide(
                                    color: Colors.blueAccent, width: 1),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child:
                                  Text(option, style: TextStyle(fontSize: 20)),
                              onPressed: () => _checkAnswer(option),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Kết thúc', style: TextStyle(fontSize: 18)),
                      onPressed: _showResultScreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
