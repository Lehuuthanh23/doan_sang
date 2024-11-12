import 'package:game_do_vui/firebase_options.dart';
import 'package:game_do_vui/screen/home_admin.dart';
import 'package:game_do_vui/screen/home_user.dart';
import 'package:game_do_vui/screen/login.dart';
import 'package:game_do_vui/screen/profile.dart';
import 'package:game_do_vui/screen/register.dart';
import 'package:game_do_vui/screen/token_frien.dart';
import 'package:game_do_vui/screen/welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Đố Vui',
      debugShowCheckedModeBanner: false,
      home: WellcomScreen(),
      routes: {
        '/homeuser': (context) => HomeUsers(),
        '/homeadmin': (context) => HomeScreenAdmin(),
        '/profile': (context) => ProfileScreen(),
        '/welcome': (context) => WellcomScreen(),
        '/notifications': (context) => FriendRequestsScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  Future<Widget> _getInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      String userRole = prefs.getString('userRole') ?? 'user';
      if (userRole == 'admin') {
        return HomeScreenAdmin();
      } else {
        return HomeUsers();
      }
    } else {
      return Login(onTap: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          return snapshot.data as Widget;
        }
      },
    );
  }
}
