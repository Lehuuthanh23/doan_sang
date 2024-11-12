import 'package:game_do_vui/screen/login.dart';
import 'package:game_do_vui/setting/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  final Function()? onTap;
  const Register({super.key, required this.onTap});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool showLogin = true;
  void togglePage() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  void login() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Login(
          onTap: togglePage,
        ),
      ),
    );
  }

  final txtEmail = TextEditingController();
  final txtUsername = TextEditingController();
  final txtPassword = TextEditingController();
  final txtConfirmPassword = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final List<String> adminEmails = [
    'admin1@example.com',
    'admin2@example.com',
    'admin3@example.com',
  ];

  void signUserUp() async {
    final usernameSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: txtUsername.text)
        .get();

    if (usernameSnapshot.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi đăng ký'),
          content:
              const Text('Tên người dùng đã tồn tại. Vui lòng chọn tên khác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: txtEmail.text,
        password: txtPassword.text,
      );

      String uid = userCredential.user!.uid;
      String role = adminEmails.contains(txtEmail.text) ? 'admin' : 'user';
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': txtUsername.text,
        'email': txtEmail.text,
        'role': role,
        'created_at': Timestamp.now(),
      });
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (txtUsername.text.isEmpty ||
          txtPassword.text.isEmpty ||
          txtConfirmPassword.text.isEmpty ||
          txtEmail.text.isEmpty) {
        errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
      } else if (txtPassword.text != txtConfirmPassword.text) {
        errorMessage = 'Mật khẩu và xác nhận mật khẩu không khớp.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email đã được sử dụng.';
      } else {
        errorMessage = 'Lỗi không xác định, vui lòng thử lại.';
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi đăng ký'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                const Icon(
                  Icons.person_add_alt_1,
                  size: 100,
                  color: Colors.black,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Đăng Ký",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: txtUsername,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tên người dùng',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: txtEmail,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: txtPassword,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Mật khẩu',
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: txtConfirmPassword,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Xác nhận mật khẩu',
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                MyButton(
                  text: "Đăng ký",
                  onTap: signUserUp,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(
                              onTap: togglePage,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Quay lại đăng nhập',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
