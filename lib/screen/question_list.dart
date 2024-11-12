import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/screen/add_question.dart';
import 'package:game_do_vui/screen/home_admin.dart';
import 'package:game_do_vui/screen/question_detail.dart';

class QuestionListScreen extends StatefulWidget {
  final String chuDeId;
  final String chuDeTitle;

  const QuestionListScreen({
    required this.chuDeId,
    required this.chuDeTitle,
  });

  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, dynamic>> questions = [];
  bool isSearching = false;
  String searchQuery = '';
  late String chuDeTitle; // For dynamic updates of topic title

  @override
  void initState() {
    super.initState();
    chuDeTitle = widget.chuDeTitle; 
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      QuerySnapshot questionSnapshot = await FirebaseFirestore.instance
          .collection('cau_hoi')
          .where('chu_de_id', isEqualTo: widget.chuDeId)
          .get();

      setState(() {
        questions = questionSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  Future<void> deleteTopic() async {
    try {
      await FirebaseFirestore.instance
          .collection('chu_de')
          .doc(widget.chuDeId)
          .delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chủ đề đã được xóa.')),
      );
    } catch (e) {
      print('Error deleting topic: $e');
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa chủ đề này không?'),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteTopic();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateTopicTitle(String newTitle) async {
    try {
      await FirebaseFirestore.instance
          .collection('chu_de')
          .doc(widget.chuDeId)
          .update({'title': newTitle});
      setState(() {
        chuDeTitle = newTitle; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tên chủ đề đã được cập nhật.')),
      );
    } catch (e) {
      print('Error updating topic title: $e');
    }
  }

  void _showRenameDialog() {
    final TextEditingController _titleController = TextEditingController(text: chuDeTitle);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đổi tên chủ đề'),
          content: TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Nhập tên chủ đề mới'),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Lưu'),
              onPressed: () {
                final newTitle = _titleController.text.trim();
                if (newTitle.isNotEmpty) {
                  Navigator.of(context).pop();
                  updateTopicTitle(newTitle);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> searchQuestions(String query) async {
    if (query.isEmpty) {
      fetchQuestions();
      return;
    }

    try {
      QuerySnapshot questionSnapshot = await FirebaseFirestore.instance
          .collection('cau_hoi')
          .where('chu_de_id', isEqualTo: widget.chuDeId)
          .get();

      setState(() {
        questions = questionSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .where((question) {
          final String questionText = question['cau_hoi_text'] ?? '';
          return questionText.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    } catch (e) {
      print('Error searching questions: $e');
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchQuery = '';
        fetchQuestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildQuestionList(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: _showDeleteConfirmationDialog,
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddQuestionScreen(
                      chuDeId: widget.chuDeId,
                    ),
                  ),
                ).then((_) => fetchQuestions());
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreenAdmin(),
                          ),
                        );
            },
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: isSearching
                ? TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm câu hỏi...',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      searchQuestions(value);
                    },
                  )
                : GestureDetector(
                    onTap: _showRenameDialog, // Tap to rename topic
                    child: Center(
                      child: Text(
                        chuDeTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            color: Colors.white,
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    if (questions.isEmpty) {
      return const Center(child: Text('Chưa có câu hỏi nào!'));
    }

    return ListView.builder(
      itemCount: questions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final question = questions[index];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  question['cau_hoi_text'] ?? 'Không có câu hỏi',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionDetailScreen(
                        question: question,
                        questionId: question['id'],
                      ),
                    ),
                  ).then((deleted) {
                    if (deleted == true) {
                      fetchQuestions();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
