import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_do_vui/screen/question_detail.dart';
import 'package:game_do_vui/screen/question_list.dart';
import 'package:game_do_vui/setting/bottom_item.dart';
import 'package:game_do_vui/setting/custum_Card.dart';

class HomeScreenAdmin extends StatefulWidget {
  const HomeScreenAdmin({super.key});

  @override
  State<HomeScreenAdmin> createState() => _HomeScreenAdminState();
}

class _HomeScreenAdminState extends State<HomeScreenAdmin> {
  String username = '';
  String profileImageUrl = '';
  int _selectedIndex = 0;
  int _currentIndex = 0;
  int _friendRequestCount = 0;
  String role = '';

  List<Map<String, dynamic>> categories = [];

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
            role = userData['role'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> fetchFriendRequestCount() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot friendRequests = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('friendRequests')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _friendRequestCount = friendRequests.docs.length;
      });
    } catch (e) {
      print('Error fetching friend requests: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot categorySnapshot =
          await FirebaseFirestore.instance.collection('chu_de').get();

      List<Map<String, dynamic>> fetchedCategories = categorySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
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

  Future<void> addCategory(String title, String icon) async {
    try {
      DocumentReference newCategoryRef =
          FirebaseFirestore.instance.collection('chu_de').doc();

      String categoryId = newCategoryRef.id;

      await newCategoryRef.set({
        'id': categoryId,
        'title': title,
        'icon': icon,
      });

      print('Category added successfully with ID: $categoryId');
      fetchCategories();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String icon = 'book';

        return AlertDialog(
          title: const Text('Thêm chủ đề mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Tên chủ đề'),
                onChanged: (value) {
                  title = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await addCategory(title, icon);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCategories();
    fetchFriendRequestCount();
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
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage: profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : const AssetImage(
                                              'assets/default_avatar.png')
                                          as ImageProvider,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // const CircleAvatar(
                                //   radius: 25,
                                //   backgroundColor: Colors.yellow,
                                // ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Chủ đề'),
                                const SizedBox(height: 8),
                                GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  children: [
                                    ...categories.map((category) {
                                      return CategoryCard(
                                        title: category['title'] ?? 'Unknown',
                                        icon: _getIconFromName(
                                            category['icon'] ?? 'book'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  QuestionListScreen(
                                                chuDeId: category['id'],
                                                chuDeTitle: category['title'],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                    CategoryCard(
                                      title: 'Thêm chủ đề',
                                      icon: Icons.add,
                                      onTap: _addCategory,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'add':
        return Icons.add;
      case 'close':
        return Icons.close;
      case 'book':
      default:
        return Icons.book;
    }
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.orange,
      ),
    );
  }
}
