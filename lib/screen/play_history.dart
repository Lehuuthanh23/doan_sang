import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PlayHistoryScreen extends StatelessWidget {
  
  String formatTimestamp(dynamic completionTime) {
    if (completionTime is Timestamp) {
      DateTime dateTime = completionTime.toDate();
      return DateFormat('dd/MM/yyyy').format(dateTime); 
    } else if (completionTime is String) {
      return completionTime; 
    }
    return 'Không xác định'; 
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                      'Lịch sử chơi',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white),
                    ),
                    const SizedBox(
                      width:
                          24),
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('playHistory') 
                            .where('userId', isEqualTo: userId) 
                            .orderBy('completionTime', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          
                          print('Fetching play history for user ID: $userId');
                          print('Snapshot data: ${snapshot.data?.docs.map((doc) => doc.data())}');

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('Chưa có lịch sử chơi nào.'));
                          }

                          final historyDocs = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true, 
                            physics: const NeverScrollableScrollPhysics(), 
                            itemCount: historyDocs.length,
                            itemBuilder: (context, index) {
                              var data = historyDocs[index].data() as Map<String, dynamic>;

                              
                              var score = data['score']?.toString() ?? 'Không có điểm';
                              var playDuration = data['playDuration'] ?? 'Không có thời gian';
                              var mode = data['mode'] ?? 'Không có chế độ';
                              var topic = data['topic'] ?? 'Không có chủ đề';
                              var questionSet = data['questionSet']?.toString() ?? 'Không có bộ câu hỏi';
                              var formattedCompletionTime = formatTimestamp(data['completionTime']);

                              return ListTile(
                                title: Text('Điểm: $score'),
                                subtitle: Text(
                                  'Thời gian chơi: $playDuration\n'
                                  'Chế độ: $mode\n'
                                  'Chủ đề: $topic\n'
                                  'Bộ câu hỏi: $questionSet\n'
                                  'Hoàn thành lúc: $formattedCompletionTime',
                                ),
                                leading: const Icon(Icons.history),
                                isThreeLine: true,
                              );
                            },
                          );
                        },
                      ),
                      const Divider(thickness: 1),
                    ],
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
