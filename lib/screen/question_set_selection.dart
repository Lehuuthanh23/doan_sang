import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/play_one.dart';

class QuestionCountSelectionScreen extends StatelessWidget {
  final String chuDeId; 

  const QuestionCountSelectionScreen({Key? key, required this.chuDeId})
      : super(key: key);

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
                      'Lựa chọn bộ câu hỏi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
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
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                child: const Text('Thoát'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(Icons.output_outlined, color: Colors.white),
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
                
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),

                        SizedBox(
                          width: 300,
                          height: 80,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayOneScreen(
                                    chuDeId: chuDeId,
                                    questionCount: 10,
                                  ),
                                ),
                              );
                            },
                            child: const Text('10 Câu Hỏi', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayOneScreen(
                                  chuDeId: chuDeId,
                                  questionCount: 20,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(300, 80), 
                          ),
                          child: const Text('20 Câu Hỏi', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: 300,
                          height: 80,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayOneScreen(
                                    chuDeId: chuDeId,
                                    questionCount: 30,
                                  ),
                                ),
                              );
                            },
                            child: const Text('30 Câu Hỏi', style: TextStyle(fontSize: 20)),
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
