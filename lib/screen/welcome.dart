import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/login.dart';
import 'package:game_do_vui/screen/register.dart';
import 'package:game_do_vui/setting/button.dart';

class WellcomScreen extends StatefulWidget {
  const WellcomScreen({super.key});

  @override
  State<WellcomScreen> createState() => _WellcomScreenState();
}

class _WellcomScreenState extends State<WellcomScreen> {
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

  void register() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Register(
          onTap: togglePage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               
                Image.asset(
                  'assets/logo3.png',
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Wellcom\nGame Đố Vui',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  child: Row(
                    children: [
                      
                      Expanded(
                        child: MyButton(
                          text: "Đăng nhập",
                          onTap: login,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: MyButton(
                          text: "Đăng ký",
                          onTap: register,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
