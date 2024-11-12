import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final txtUs = TextEditingController();

  @override
  void dispose() {
    txtUs.dispose();
    super.dispose();
  }

  Future passReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: txtUs.text.trim());
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Nhận thông báo thay đổi password ở Gmail!'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'))
              ],
            );
          });
    } on FirebaseAuthException {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Không tìm thấy email!'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'))
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/Background.jpg',
              fit: BoxFit.cover, 
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.lock_open,
                    size: 100,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    "Tìm lại tài khoản!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: Colors.black, 
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Nhập đúng Gmail đã dùng để đăng ký",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black, 
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: txtUs,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nhập email',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MaterialButton(
                      onPressed: passReset,
                      color: Colors.black,
                      child: const Text(
                        'Reset password!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
