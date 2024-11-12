import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/add_frien.dart';
import 'package:game_do_vui/screen/token_frien.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  void initState() {
    super.initState();
  }


Future<List<Map<String, dynamic>>> _getFriends() async {
  String currentUserId = _auth.currentUser!.uid;


  QuerySnapshot friendsSnapshot1 = await _firestore
      .collection('friends')
      .where('userId1', isEqualTo: currentUserId)
      .get();


  QuerySnapshot friendsSnapshot2 = await _firestore
      .collection('friends')
      .where('userId2', isEqualTo: currentUserId)
      .get();

  List<Map<String, dynamic>> friends = [];

  for (var doc in friendsSnapshot1.docs) {
    String friendId = doc['userId2'];

    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(friendId).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> friendData =
          userSnapshot.data() as Map<String, dynamic>;
      friends.add({
        'uid': friendId,
        'username': friendData['username'] ?? 'Unknown',
        'profile_image':
            friendData['profile_image'] ?? 'assets/default_avatar.png',
        'status': friendData['status'] ?? 'offline',
      });
    }
  }


  for (var doc in friendsSnapshot2.docs) {
    String friendId = doc['userId1'];

    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(friendId).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> friendData =
          userSnapshot.data() as Map<String, dynamic>;
      friends.add({
        'uid': friendId,
        'username': friendData['username'] ?? 'Unknown',
        'profile_image':
            friendData['profile_image'] ?? 'assets/default_avatar.png',
        'status': friendData['status'] ?? 'offline',
      });
    }
  }

  return friends;
}


  Future<void> _confirmAndDeleteFriend(String friendId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận xóa bạn bè"),
          content: const Text("Bạn có chắc muốn xóa bạn này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); 
              },
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); 
              },
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _deleteFriend(friendId);
    }
  }

  Future<void> _deleteFriend(String friendId) async {
    String currentUserId = _auth.currentUser!.uid;

    try {

      QuerySnapshot snapshot = await _firestore
          .collection('friends')
          .where('userId1', isEqualTo: currentUserId)
          .where('userId2', isEqualTo: friendId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {}); 
    } catch (e) {
      print('Error deleting friend: $e');
    }
  }

  void _navigateToAddFriendScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFriendScreen()),
    );
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/profile');
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Danh sách bạn bè',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: _navigateToAddFriendScreen,
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
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getFriends(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Lỗi: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('Không có bạn bè nào.'));
                          } else {
                            List<Map<String, dynamic>> friends = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> friend = friends[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: friend['profile_image']
                                            .startsWith('assets/')
                                        ? AssetImage(friend['profile_image'])
                                            as ImageProvider
                                        : NetworkImage(friend['profile_image']),
                                  ),
                                  title: Text(friend['username']),
                                  subtitle: Text(friend['status'] == 'online' ? 'Online' : 'Offline'),

                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmAndDeleteFriend(friend['uid']),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
