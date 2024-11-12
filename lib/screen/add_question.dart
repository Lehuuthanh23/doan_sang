import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/setting/button.dart';

class AddQuestionScreen extends StatefulWidget {
  final String chuDeId;

  const AddQuestionScreen({required this.chuDeId});

  @override
  _AddQuestionScreenState createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  String questionText = '';
  String correctAnswer = '';
  List<String> wrongAnswers = ['', '', '']; 

  Future<void> addQuestion() async {
    if (questionText.isNotEmpty && correctAnswer.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('cau_hoi').add({
          'chu_de_id': widget.chuDeId,
          'cau_hoi_text': questionText,
          'cau_tra_loi_dung': correctAnswer,
          'dap_an_sai': wrongAnswers,
        });
        Navigator.of(context).pop(); 
      } catch (e) {
        print('Error adding question: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Thêm câu hỏi mới',
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(30), 
                      ),
                      padding: const EdgeInsets.all(20), 
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildPillTextField(
                              label: 'Câu hỏi',
                              onChanged: (value) => questionText = value,
                            ),
                            const SizedBox(height: 10),
                            buildPillTextField(
                              label: 'Đáp án đúng',
                              onChanged: (value) => correctAnswer = value,
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(wrongAnswers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: buildPillTextField(
                                  label: 'Đáp án sai ${index + 1}',
                                  onChanged: (value) => wrongAnswers[index] = value,
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            MyButton(onTap: addQuestion, text: 'Thêm câu hỏi')
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
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 18), 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }
}
