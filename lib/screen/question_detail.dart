
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/screen/edit_question.dart';

class QuestionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> question;
  final String questionId;

  const QuestionDetailScreen({
    required this.question,
    required this.questionId,
  });

  @override
  _QuestionDetailScreenState createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  late Map<String, dynamic> question;
  late String questionId;

  @override
  void initState() {
    super.initState();
    question = widget.question;
    questionId = widget.questionId;
  }

  void _editQuestion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(
          questionId: questionId,
          existingQuestionData: question,
        ),
      ),
    ).then((_) {
      _loadQuestionData();
    });
  }

  Future<void> _loadQuestionData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('cau_hoi')
          .doc(questionId)
          .get();

      setState(() {
        question = doc.data() as Map<String, dynamic>;
      });
    } catch (e) {
      print('Error loading question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load question data.')),
      );
    }
  }

  void _deleteQuestion(BuildContext context) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa câu hỏi'),
          content: const Text('Bạn có chắc chắn muốn xóa câu hỏi này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance.collection('cau_hoi').doc(questionId).delete();
        Navigator.pop(context, true); 
      } catch (e) {
        print('Error deleting question: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete question. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> wrongAnswers = question['dap_an_sai'] ?? [];
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Background.jpg'), 
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
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
                      'Chi tiết câu hỏi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _editQuestion(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteQuestion(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
          
              Center(
                child: Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Câu hỏi: ${question['cau_hoi_text'] ?? 'Không có câu hỏi'}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Đáp án đúng: ${question['cau_tra_loi_dung'] ?? 'Không có đáp án'}',
                          style: const TextStyle(fontSize: 20), 
                        ),
                        const SizedBox(height: 10),
            
                        const Text('Các đáp án sai:', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 10),
                        for (int i = 0; i < wrongAnswers.length; i++)
                          Text('Đáp án sai ${i + 1}: ${wrongAnswers[i] ?? 'Không có đáp án'}',
                              style: const TextStyle(fontSize: 18)), 
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
