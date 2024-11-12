import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchQuestions(
      String chuDeId, int questionCount) async {
    try {
      final querySnapshot = await _firestore
          .collection('cau_hoi')
          .where('chu_de_id', isEqualTo: chuDeId)
          .limit(questionCount)
          .get();

      return querySnapshot.docs
          .take(questionCount)
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList()
        ..shuffle();
    } catch (e) {
      print('Error fetching questions: $e');
      throw Exception('Không thể tải câu hỏi, vui lòng thử lại.');
    }
  }

  Future<String> fetchTopicName(String chuDeId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('chu_de').doc(chuDeId).get();

      if (snapshot.exists) {
        return snapshot['title'] ?? 'Chủ đề không xác định';
      } else {
        return 'Chủ đề không tồn tại';
      }
    } catch (e) {
      print('Lỗi khi lấy tên chủ đề: $e');
      return 'Lỗi lấy tên chủ đề';
    }
  }
}
