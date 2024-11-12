import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/edit_profile.dart';
import 'package:game_do_vui/screen/list_frien.dart';
import 'package:game_do_vui/screen/login.dart';
import 'package:game_do_vui/screen/play_history.dart';
import 'package:game_do_vui/screen/welcome.dart';
import 'package:game_do_vui/service/is_Offline.dart';
import 'package:game_do_vui/setting/bottom_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String email = '';
  String? profileImageUrl;
  File? _imageFile;
  String role = '';
  int _selectedIndex = 0;
  String userId = '';
  int _currentIndex = 2;
  int _friendRequestCount = 0;
  bool isLoading = true;
  bool isAdmin = true;

  List<Map<String, dynamic>> playHistoryList = [];

  void fetchPlayHistory(String userId) async {
    playHistoryList.clear();

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('playHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('completionTime', descending: true)
          .get();

      print('Fetched documents: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        playHistoryList.add(doc.data() as Map<String, dynamic>);
        print(doc.data());
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error fetching play history: $e');
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
            username = userData['username'] ?? 'Chưa có tên người dùng';
            email = userData['email'] ?? 'Chưa có email';
            profileImageUrl = userData['profile_image'];
            role = userData['role'] ?? 'user';
            isAdmin = role == 'admin'; 
          });
        }
      } else {
        throw Exception('Không tìm thấy dữ liệu người dùng.');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi'),
          content: const Text('Không thể lấy dữ liệu người dùng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String filePath = 'img/$uid/profile.jpg';

      await FirebaseStorage.instance.ref(filePath).putFile(_imageFile!);

      String downloadURL =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profile_image': downloadURL});

      setState(() {
        profileImageUrl = downloadURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ảnh đại diện đã được tải lên thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải lên ảnh thất bại!')),
      );
    }
  }

  Future<void> _lichsu() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayHistoryScreen(),
      ),
    );
  }

  Future<void> setUserStatus(String userId, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': status,
    });
  }

  Future<void> _logout(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (user != null) {
      String userId = user.uid;

      await setUserStatus(userId, 'offline');
      await setUserOffline();

      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Login(onTap: () {})),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      if (role.isNotEmpty) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(
                context, role == 'admin' ? '/homeadmin' : '/homeuser');
            break;
          case 1:
            if (role != 'admin') {
              Navigator.pushNamed(context, '/notifications');
            }
            break;
          case 2:
            break;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      fetchFriendRequestCount();
      fetchPlayHistory(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      'Thông Tin Cá Nhân',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Wrap(
                              children: [
                                if (!isAdmin)
                                  ListTile(
                                    leading: const Icon(Icons.history),
                                    title: const Text('Xem lịch sử chơi'),
                                    onTap: _lichsu,
                                  ),
                                if (!isAdmin)
                                  ListTile(
                                    leading:
                                        const Icon(Icons.supervisor_account),
                                    title: const Text('Quản lý bạn bè'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const FriendsListScreen()),
                                      );
                                    },
                                  ),
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title:
                                      const Text('Chỉnh sửa thông tin cá nhân'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.logout),
                                  title: const Text('Đăng xuất'),
                                  onTap: () {
                                    _logout(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
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
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null ||
                                  profileImageUrl!.isEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _pickImage,
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              buildProfileInfo('Tên người dùng', username),
                              const SizedBox(height: 10),
                              buildProfileInfo('Email', email),
                              const SizedBox(height: 10),
                              buildProfileInfo(
                                  'Vai trò',
                                  role == 'admin'
                                      ? 'Quản trị viên'
                                      : 'Người dùng'),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Lịch chơi gần đây',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('playHistory')
                              .where('userId', isEqualTo: userId)
                              .orderBy('completionTime', descending: true)
                              .limit(5)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            print('Fetching play history for user ID: $userId');
                            print(
                                'Snapshot data: ${snapshot.data?.docs.map((doc) => doc.data())}');

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('Chưa có lịch sử chơi nào.'));
                            }

                            final historyDocs = snapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: historyDocs.length,
                              itemBuilder: (context, index) {
                                var data = historyDocs[index].data()
                                    as Map<String, dynamic>;

                                var score = data['score']?.toString() ??
                                    'Không có điểm';

                                var mode = data['mode'] ?? 'Không có chế độ';

                                var formattedCompletionTime =
                                    formatTimestamp(data['completionTime']);

                                return ListTile(
                                  title: Text('Điểm: $score'),
                                  subtitle: Text(
                                    'Chế độ: $mode'
                                    ' Chơi ngày: $formattedCompletionTime',
                                  ),
                                  leading: const Icon(Icons.history),
                                  isThreeLine: true,
                                );
                              },
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ))
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

  Widget buildProfileInfo(String title, String info) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Flexible(
          child: Text(
            info,
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String formatTimestamp(dynamic completionTime) {
  if (completionTime is Timestamp) {
    DateTime dateTime = completionTime.toDate();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  } else if (completionTime is String) {
    return completionTime;
  }
  return 'Không xác định';
}
