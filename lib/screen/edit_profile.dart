import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_do_vui/setting/button.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _usernameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
    }
  }

  Future<void> _updateProfileAndPassword() async {
    try {
      String uid = user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      await user!.updateDisplayName(_usernameController.text.trim());
      await user!.updateEmail(_emailController.text.trim());

      String oldPassword = _oldPasswordController.text.trim();
      String newPassword = _newPasswordController.text.trim();

      if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
        String email = user!.email!;
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: oldPassword,
        );

        await user!.reauthenticateWithCredential(credential);
        await user!.updatePassword(newPassword);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    }
  }

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
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa thông Tin Cá Nhân',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          const InputDecoration(labelText: 'Tên người dùng'),
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const Divider(height: 40),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                    ),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Mật khẩu mới'),
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: _updateProfileAndPassword,
                      text: 'Cập nhật',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
