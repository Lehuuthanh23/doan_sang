import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/setting/bottom_item.dart';

import '../model/room.dart';
import 'room_information.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _playRequests = [];
  int _currentIndex = 1;
  int _friendRequestCount = 0;
  String? role;
  bool _isLoading = true;
  late TabController _tabController;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserRole();
    await _fetchPlayRequests();
    await _fetchFriendRequests();
    await fetchCategories();
    setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    setState(() {
      role = userDoc['role'];
    });
  }

  Future<void> _fetchPlayRequests() async {
    String? email = _auth.currentUser!.email;

    QuerySnapshot playRequestsSnapshot = await _firestore
        .collection('notifications')
        .where('user.email', isEqualTo: email)
        .get();
    setState(() {
      _playRequests = playRequestsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _fetchFriendRequests() async {
    String uid = _auth.currentUser!.uid;

    QuerySnapshot friendRequestsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    List<Map<String, dynamic>> requests = [];

    for (var doc in friendRequestsSnapshot.docs) {
      Map<String, dynamic> requestData = doc.data() as Map<String, dynamic>;
      requestData['requestId'] = doc.id;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(requestData['fromUserId'])
          .get();
      if (userDoc.exists) {
        requestData['fromUsername'] = userDoc['username'];
      }

      requests.add(requestData);
    }

    setState(() {
      _friendRequests = requests;
      _friendRequestCount = requests.length;
    });
  }

  Future<void> _acceptFriendRequest(String fromUserId, String requestId) async {
    String toUserId = _auth.currentUser!.uid;
    try {
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      await _firestore.collection('friends').add({
        'userId1': fromUserId,
        'userId2': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yêu cầu kết bạn đã được chấp nhận.')),
      );

      _fetchFriendRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chấp nhận yêu cầu kết bạn: $e')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    String uid = _auth.currentUser!.uid;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('friendRequests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yêu cầu kết bạn đã bị từ chối.')),
      );

      _fetchFriendRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi từ chối yêu cầu kết bạn: $e')),
      );
    }
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      switch (index) {
        case 0:
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/homeadmin');
          } else {
            Navigator.pushReplacementNamed(context, '/homeuser');
          }
          break;
        case 1:
          break;
        case 2:
          Navigator.pushNamed(context, '/profile');
          break;
      }
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
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    const Text(
                      'Thông báo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              const SizedBox(height: 10),
                              TabBar(
                                controller: _tabController,
                                tabs: [
                                  Tab(text: 'Yêu cầu kết bạn'),
                                  Tab(text: 'Mời chơi'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _friendRequests.isEmpty
                                        ? const Center(
                                            child: Text(
                                                'Không có thông báo nào tới bạn nào.'),
                                          )
                                        : ListView.builder(
                                            itemCount: _friendRequests.length,
                                            itemBuilder: (context, index) {
                                              var request =
                                                  _friendRequests[index];
                                              return Card(
                                                elevation: 2,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: ListTile(
                                                  title: Text(
                                                    'Yêu cầu kết bạn từ ${request['fromUsername'] ?? 'Unknown'}',
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.check,
                                                            color:
                                                                Colors.green),
                                                        onPressed: () =>
                                                            _acceptFriendRequest(
                                                          request['fromUserId'],
                                                          request['requestId'],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.red),
                                                        onPressed: () =>
                                                            _rejectFriendRequest(
                                                                request[
                                                                    'requestId']),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                    _playRequests.isEmpty
                                        ? const Center(
                                            child: Text(
                                                'Không có thông báo mời chơi nào tới bạn nào.'),
                                          )
                                        : ListView.builder(
                                            itemCount: _playRequests.length,
                                            itemBuilder: (context, index) {
                                              var request =
                                                  _playRequests[index];
                                              return Card(
                                                elevation: 2,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: ListTile(
                                                  title: Text(
                                                    'Yêu cầu chơi từ ${request["owner"]["username"]}',
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                          icon: const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.green),
                                                          onPressed: () async {
                                                            DocumentSnapshot
                                                                roomSnapshot =
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'rooms')
                                                                    .doc(request[
                                                                            "room"]
                                                                        ["id"])
                                                                    .get();
                                                            if (roomSnapshot
                                                                .exists) {
                                                              String userId =
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid;

                                                              // Thêm người dùng vào danh sách `users`
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'rooms')
                                                                  .doc(request[
                                                                          "room"]
                                                                      ["id"])
                                                                  .update({
                                                                'users': FieldValue
                                                                    .arrayUnion(
                                                                        [userId])
                                                              });
                                                              Room room = Room(
                                                                id: request[
                                                                        "room"]
                                                                    ["id"],
                                                                password: request[
                                                                        "room"][
                                                                    "password"],
                                                                questionCount:
                                                                    request["room"]
                                                                        [
                                                                        "questionCount"],
                                                                users: List<
                                                                    String>.from(request[
                                                                        "room"]
                                                                    ["users"]),
                                                                topicId: request[
                                                                        "room"]
                                                                    ["topicId"],
                                                                isStarted: request[
                                                                        "room"][
                                                                    "isStarted"],
                                                                isPlaying: request[
                                                                        "room"][
                                                                    "isPlaying"],
                                                              );
                                                              Map<String,
                                                                      dynamic>
                                                                  categoryData =
                                                                  categories
                                                                      .firstWhere(
                                                                (category) {
                                                                  print(
                                                                      'Alo ${category}');
                                                                  return category[
                                                                          'id'] ==
                                                                      room.topicId;
                                                                },
                                                                orElse: () => {
                                                                  'title':
                                                                      'Unknown'
                                                                },
                                                              );
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'notifications')
                                                                  .doc(request[
                                                                      "id"])
                                                                  .delete();
                                                              print(
                                                                  'Xoassss ${request["id"]}');
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => ThongTinPhong(
                                                                      room:
                                                                          room,
                                                                      categories:
                                                                          categoryData),
                                                                ),
                                                              );
                                                            } else {
                                                              print(
                                                                  'Room not found.');
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                    content: Text(
                                                                        'Room not found.')),
                                                              );
                                                            }
                                                          }),
                                                      IconButton(
                                                          icon: const Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () async {
                                                            DocumentSnapshot
                                                                roomSnapshot =
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'rooms')
                                                                    .doc(request[
                                                                        "id"])
                                                                    .get();
                                                            if (roomSnapshot
                                                                .exists) {
                                                              print(
                                                                  'Xoas ${request["id"]}');
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'notifications')
                                                                  .doc(request[
                                                                          "room"]
                                                                      ["id"])
                                                                  .delete();
                                                            } else {
                                                              print(
                                                                  'Room not found.');
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                    content: Text(
                                                                        'Room not found.')),
                                                              );
                                                            }
                                                          }),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  )),
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
