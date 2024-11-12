import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/screen/forgot_password.dart';
import 'package:game_do_vui/screen/register.dart';
import 'package:game_do_vui/service/service_gg.dart';
import 'package:game_do_vui/setting/SquareTile.dart';
import 'package:game_do_vui/setting/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  final Function()? onTap;
  const Login({super.key, required this.onTap});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final txt_us = TextEditingController();
  final txt_pass = TextEditingController();
  bool isPasswordVisible = false;
  DocumentReference? notiRef;
  StreamSubscription<DocumentSnapshot>? roomSubscription;

  Future<void> signUserIn() async {
    try {
      String email = txt_us.text;
      if (!txt_us.text.contains('@')) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: txt_us.text)
            .get();

        if (userQuery.docs.isEmpty) {
          showLoginError('user-not-found');
          return;
        }

        email = userQuery.docs.first['email'];
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: txt_pass.text,
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await setUserStatus(user.uid, 'online');

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String role = userDoc.data()?['role'] ?? 'user';

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', role);
        await prefs.setBool('isLoggedIn', true);
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/homeadmin');
        } else {
          Navigator.pushReplacementNamed(context, '/homeuser');
        }
      }
    } on FirebaseAuthException catch (e) {
      showLoginError(e.code);
    }
  }

  Future<void> googleSignIn() async {
    try {
      User? user = await GG_service().signInGG();
      if (user != null) {
        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': user.email,
            'username': user.displayName,
            'role': 'user',
            'status': 'online',
          });
        } else {
          await setUserStatus(user.uid, 'online');
        }

        Navigator.pushReplacementNamed(context, '/homeuser');
      }
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Lỗi đăng nhập'),
          content: Text('Đăng nhập Google không thành công: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Lỗi đăng nhập'),
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
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

  Future<void> setUserStatus(String userId, String status) async {
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({'status': status});
    } else {
      await userDoc.update({'status': status});
    }
  }

  void showLoginError(String errorCode) {
    String errorMessage;
    if (txt_us.text.isEmpty || txt_pass.text.isEmpty) {
      errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
    } else if (errorCode == 'user-not-found') {
      errorMessage = 'Tài khoản không tồn tại.';
    } else if (errorCode == 'wrong-password') {
      errorMessage = 'Sai mật khẩu.';
    } else {
      errorMessage = 'Lỗi đăng nhập. Vui lòng thử lại.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi đăng nhập'),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.2),
                          const Text(
                            "Đăng nhập",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 36),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Chào mừng bạn đến với ứng dụng!",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const SizedBox(height: 50),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextField(
                                  controller: txt_us,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Nhập tên người dùng của bạn',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextField(
                                  obscureText: !isPasswordVisible,
                                  controller: txt_pass,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Nhập mật khẩu',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordVisible =
                                              !isPasswordVisible;
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
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPass()),
                                    );
                                  },
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1),
                            child: MyButton(
                              text: "Đăng nhập",
                              onTap: signUserIn,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Chưa có tài khoản? ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Register(onTap: widget.onTap),
                                  ),
                                ),
                                child: const Text(
                                  'Đăng ký ngay ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              squareTile(
                                onTap: googleSignIn,
                                imagePath: 'assets/logogoogle.png',
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
