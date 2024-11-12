import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_do_vui/model/room.dart';
import 'package:game_do_vui/screen/game_mode.dart';
import 'package:game_do_vui/screen/play_history.dart';
import 'package:game_do_vui/screen/ranking.dart';
import 'package:game_do_vui/setting/bottom_item.dart';

class HomeUsers extends StatefulWidget {
  const HomeUsers({super.key});

  @override
  State<HomeUsers> createState() => _HomeUsersState();
}

class _HomeUsersState extends State<HomeUsers> {
  String username = '';
  String profileImageUrl = '';
  int _friendRequestCount = 0;
  int _selectedIndex = 0;
  int _currentIndex = 0;
  List<String> listFriend = [];
  List<Map<String, dynamic>> categories = [];
  TextEditingController friendController = TextEditingController();
  List<String> friendRequest = [];
  late Map<String, dynamic> category;
  String role = '';

  Future<void> fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          setState(() {
            username = userData['username'] ?? 'Unknown';
            profileImageUrl = userData['profile_image'] ?? '';
            listFriend = List<String>.from(userData['listFriend'] ?? []);
            friendRequest = List<String>.from(userData['friendRequest'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      switch (index) {
        case 0:
          break;
        case 1:
          if (role != 'admin') {
            Navigator.pushNamed(context, '/notifications');
          }
          break;
        case 2:
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot categorySnapshot =
          await FirebaseFirestore.instance.collection('chu_de').get();

      List<Map<String, dynamic>> fetchedCategories = categorySnapshot.docs
          .map((doc) => {
                'id': doc.id, // Add the document ID to the map
                ...doc.data() as Map<String, dynamic>, // Include other fields
              })
          .toList();

      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
    print('Notification $notificationId deleted');
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      minRadius: 30,
                      maxRadius: 50,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    Text(
                      username,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 90.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 16, 226, 9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                        icon: Icon(Icons.star_half_rounded),
                        color: Colors.black,
                        iconSize: 30,
                        onPressed: () {}),
                  ),
                  SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 16, 226, 9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                        icon: Icon(Icons.scoreboard_outlined),
                        color: Colors.black,
                        iconSize: 30,
                        onPressed: () {}),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đố Vui',
                    style: TextStyle(
                      fontSize: 60,
                      fontFamily: 'Lobster',
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GameMode()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Play',
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Domine',
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
          friendRequestCount: _friendRequestCount,
          isAdmin: role == 'admin',
        ),
      ),
    );
  }
}
