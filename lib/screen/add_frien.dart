import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:game_do_vui/screen/list_frien.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _searchResults = [];
  String _usernameToSearch = '';

  void _searchUser() async {
    if (_usernameToSearch.isNotEmpty) {
      try {
        
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: _usernameToSearch)
            .get();

        setState(() {
          _searchResults = snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'uid': doc.id, 
              ...data,
            };
          }).toList();
        });
      } catch (e) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String friendUserId) async {
    String uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(friendUserId)
        .collection('friendRequests')
        .doc(uid) 
        .set({
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'fromUserId': uid,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Yêu cầu kết bạn đã được gửi đến $_usernameToSearch')),
    );
    setState(() {
      _searchResults.clear();
      _usernameToSearch = ''; 
    });
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendsListScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(), 
                    const Text(
                      'Thêm bạn mới',
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Tìm kiếm theo tên người dùng',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _usernameToSearch = value;
                            });
                          },
                          onSubmitted: (value) {
                            _searchUser();
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _searchUser,
                          child: const Text('Tìm kiếm'),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            var user = _searchResults[index];
                            return ListTile(
                              title: Text(user['username'] ?? 'N/A'),
                              subtitle: Text(user['status'] == 'online'
                                  ? 'Online'
                                  : 'Offline'),
                              trailing: ElevatedButton(
                                onPressed: () =>
                                    _sendFriendRequest(user['uid']),
                                child: const Text('Thêm bạn'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
