import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/setting/button.dart';

class EditQuestionScreen extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> existingQuestionData;

  const EditQuestionScreen({
    required this.questionId,
    required this.existingQuestionData,
  });

  @override
  _EditQuestionScreenState createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  late String questionText;
  late String correctAnswer;
  late String wrongAnswer1;
  late String wrongAnswer2;
  late String wrongAnswer3;

  @override
  void initState() {
    super.initState();
    questionText = widget.existingQuestionData['cau_hoi_text'] ?? '';
    correctAnswer = widget.existingQuestionData['cau_tra_loi_dung'] ?? '';
    wrongAnswer1 = widget.existingQuestionData['dap_an_sai'][0] ?? '';
    wrongAnswer2 = widget.existingQuestionData['dap_an_sai'][1] ?? '';
    wrongAnswer3 = widget.existingQuestionData['dap_an_sai'][2] ?? '';
  }

  Future<void> _updateQuestion() async {
    if (questionText.isNotEmpty &&
        correctAnswer.isNotEmpty &&
        wrongAnswer1.isNotEmpty &&
        wrongAnswer2.isNotEmpty &&
        wrongAnswer3.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('cau_hoi')
          .doc(widget.questionId)
          .update({
        'cau_hoi_text': questionText,
        'cau_tra_loi_dung': correctAnswer,
        'dap_an_sai': [wrongAnswer1, wrongAnswer2, wrongAnswer3],
      });

      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                        'Sửa câu hỏi',
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(30), 
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildPillTextField(
                              label: 'Câu hỏi',
                              initialValue: questionText,
                              onChanged: (value) {
                                setState(() {
                                  questionText = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            buildPillTextField(
                              label: 'Đáp án đúng',
                              initialValue: correctAnswer,
                              onChanged: (value) {
                                setState(() {
                                  correctAnswer = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            const Text('Các đáp án sai:',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            buildPillTextField(
                              label: 'Đáp án sai 1',
                              initialValue: wrongAnswer1,
                              onChanged: (value) {
                                setState(() {
                                  wrongAnswer1 = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            buildPillTextField(
                              label: 'Đáp án sai 2',
                              initialValue: wrongAnswer2,
                              onChanged: (value) {
                                setState(() {
                                  wrongAnswer2 = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            buildPillTextField(
                              label: 'Đáp án sai 3',
                              initialValue: wrongAnswer3,
                              onChanged: (value) {
                                setState(() {
                                  wrongAnswer3 = value;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            MyButton(
                              onTap: _updateQuestion,
                              text:  'Cập nhật câu hỏi',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget buildPillTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 18),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }
}
