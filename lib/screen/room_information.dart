import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_do_vui/model/room.dart';
import 'package:game_do_vui/screen/play_question.dart';

class ThongTinPhong extends StatefulWidget {
  ThongTinPhong({super.key, required this.room, required this.categories});
  Room room;
  final Map<String, dynamic> categories;

  @override
  State<ThongTinPhong> createState() => _ThongTinPhongState();
}

class _ThongTinPhongState extends State<ThongTinPhong> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> userAvatars = [];
  StreamSubscription<DocumentSnapshot>? roomSubscription;
  String username = '';
  bool isStarted = false;
  bool isPlaying = false;
  bool isPlayingNavigated = false;
  bool isSecondPlayer =
      false; // Xác định xem bạn có phải là người chơi thứ 2 không
  bool isReady = false;
  bool isRoomAdmin = false;
  DocumentReference? notiRef;
  Room? currentRoom;
  @override
  void initState() {
    print('hahahaha');
    super.initState();
    _checkIfSecondPlayer();
    fetchUserData();
    _listenToRoomChanges();
  }

  Future<void> removeCurrentUserFromRoom() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    List<String> users = currentRoom!.users;
    users.remove(currentUserId);
    if (isSecondPlayer) {
      try {
        // Xóa người chơi thứ hai khỏi danh sách 'users' trong phòng
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .update({
          'users': users,
          'isStarted': false, // Cập nhật 'isStarted' thành false khi thoát
          'isPlaying': false
        });
        print(
            'Đã xóa người chơi thứ hai khỏi phòng và cập nhật isStarted thành false');
      } catch (e) {
        print('Lỗi khi xóa người chơi thứ hai khỏi phòng: $e');
      }
    } else {
      // Nếu người tạo phòng thoát, cũng cập nhật 'isStarted' thành false
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.room.id)
          .update({'isStarted': false, 'isPlaying': false, 'users': users});
      print('Người tạo phòng thoát, cập nhật isStarted thành false');
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
            username = userData['username'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _checkIfSecondPlayer() async {
    // Lấy ID của người dùng hiện tại
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Kiểm tra nếu ID người dùng hiện tại là người thứ hai trong danh sách phòng
    setState(() {
      isSecondPlayer = widget.room.users.length == 2 &&
          widget.room.users[1] == currentUserId;
      isRoomAdmin = widget.room.users[0] ==
          currentUserId; // Nếu là người đầu tiên trong danh sách, là admin
    });
  }

  void _listenToRoomChanges() {
    print("Id rooommmm: " + widget.room.id);
    notiRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.room.id);

    // Lắng nghe thay đổi từ tài liệu
    roomSubscription = notiRef!.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        currentRoom = Room.fromJson(data);
        List<String> userIds = List<String>.from(data['users'] ?? []);
        print('data nè: ${data}');
        // Lấy avatar cho mỗi userId
        List<String> avatars = await _fetchUserAvatars(userIds);

        // Cập nhật biến userAvatars
        setState(() {
          isSecondPlayer = userIds.length == 2 &&
              userIds[1] == FirebaseAuth.instance.currentUser!.uid;
          isRoomAdmin = userIds.length > 0 &&
              userIds[0] == FirebaseAuth.instance.currentUser!.uid;
          userAvatars = avatars;
          print(data['isStarted']);
          isStarted = data['isStarted'] as bool;
          bool isPlaying = data['isPlaying'] as bool;
          print('isPlaying: ${isPlaying}');
          if (isRoomAdmin) {
            // Admin có nút "Bắt đầu"
            isStarted = data['isStarted'] ?? false;
          } else if (isSecondPlayer) {
            // Người chơi thứ hai có nút "Sẵn sàng"
            isReady = data['isStarted'] ?? false;
          }
          if (isPlaying) {
            print('Vào chơi nè ${widget.categories['id']}');
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PlayQuestion(
                        categories: widget.categories,
                        topicId: widget.categories['id'],
                        questionCount: widget.room.questionCount,
                        users: List<String>.from(data['users']),
                        room: currentRoom!,
                      )),
            );
          }
          print('Gans xong: ${isStarted}');
        });
      }
    });
  }

  // Hàm lấy avatar của từng người dùng
  Future<List<String>> _fetchUserAvatars(List<String> userIds) async {
    List<String> avatars = [];
    for (String userId in userIds) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      if (userData != null) {
        avatars.add(userData['profile_image'] ?? 'default_avatar_url');
      } else {
        avatars.add('default_avatar_url');
      }
    }
    return avatars;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    roomSubscription!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  IconButton(
                    onPressed: () async {
                      await removeCurrentUserFromRoom();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),
                  ),
                  const Text(
                    'Đối Kháng',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF9D9191),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Thông tin phòng',
                            style: TextStyle(fontSize: 30),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTile(
                                    label: 'ID',
                                    value: widget.room.id,
                                  ),
                                  CustomTile(
                                    label: 'Password',
                                    value: widget.room.password,
                                  ),
                                  CustomTile(
                                    label: 'Quản trị',
                                    value: '$username',
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTile(
                                    label: 'Người tham gia',
                                    value: '2',
                                  ),
                                  CustomTile(
                                    label: 'Chủ đề',
                                    value: widget.categories['title'],
                                  ),
                                  CustomTile(
                                    label: 'Số lượng câu',
                                    value: widget.room.questionCount,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                height: 70,
                                width: 70,
                                child: CircleAvatar(
                                  backgroundImage: userAvatars.isNotEmpty
                                      ? NetworkImage(userAvatars[0])
                                      : AssetImage('assets/default_avatar.png')
                                          as ImageProvider,
                                ),
                              ),
                              Positioned(
                                height: 110,
                                left: 50,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.red,
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 70,
                            width: 70,
                            child: CircleAvatar(
                              backgroundImage: userAvatars.length > 1
                                  ? NetworkImage(userAvatars[1])
                                  : AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (!isSecondPlayer)
                          InkWell(
                            onTap: () {
                              if (userAvatars.length == 1) {
                                showCustomDialog(context);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  color: userAvatars.length == 1
                                      ? Colors.blue
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('Mời'),
                            ),
                          ),
                        InkWell(
                          onTap: () async {
                            if (isSecondPlayer) {
                              // Khi nhấn nút, đảo ngược trạng thái `isReady`
                              setState(() {
                                isReady = !isReady;
                              });

                              // Cập nhật `isStarted` trong Firestore theo trạng thái `isReady`
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.room.id)
                                  .update({
                                'isStarted': isReady,
                              });

                              print(isReady
                                  ? "Bạn đã sẵn sàng."
                                  : "Bạn đã hủy sẵn sàng.");
                            } else {
                              if (isStarted) {
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(widget.room.id)
                                    .update({
                                  'isPlaying': true,
                                });
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => PlayQuestion(),
                                //   ),
                                // );
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isReady && isSecondPlayer
                                  ? Colors.red
                                  : isStarted
                                      ? Colors.blue
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isReady && isSecondPlayer
                                  ? 'Đã sẵn sàng'
                                  : (isSecondPlayer ? 'Sẵn sàng' : 'Bắt đầu'),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (userDoc.exists) {
        Map<String, dynamic> user = userDoc.data() as Map<String, dynamic>;
        return user;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Failed to fetch user data');
    }
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

//mời người dung qua email, chưa kết bạn
  void _showInviteDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mời người dùng'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Nhập email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                // Thực hiện hành động mời, ví dụ in email ra console
                print('Đã mời: ${emailController.text}');
                inviteUser(emailController.text);
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text('Mời'),
            ),
          ],
        );
      },
    );
  }

//mời qua danh sách bạn bè
  void _showInviteFriends(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Danh Sách Bạn Bè"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getFriends(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Không có bạn bè nào.'));
                  } else {
                    List<Map<String, dynamic>> friends = snapshot.data!;
                    return Column(
                      children: friends.map((friend) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                friend['profile_image'].startsWith('assets/')
                                    ? AssetImage(friend['profile_image'])
                                        as ImageProvider
                                    : NetworkImage(friend['profile_image']),
                          ),
                          title: Text(friend['username']),
                          subtitle: Text(friend['status'] == 'online'
                              ? 'Online'
                              : 'Offline'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_box_outlined,
                                color: Colors.red),
                            onPressed: () {
                              // Mời bạn bè
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng hộp thoại
            },
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

//nút mời showdialog
  void showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Mời bạn bè"),
          ],
        ),
        content: SizedBox(
          height: 100,
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _showInviteFriends(context);
                    },
                    child: const Text("Danh sách bạn bè"),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _showInviteDialog(context);
                    },
                    child: const Text("Email người dùng"),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng hộp thoại
            },
            child: const Text("Hủy"),
          ),
        ],
      ),
    );
  }

  inviteUser(email) async {
    String? currentUserEmail = await _auth.currentUser!.email;
    Map<String, dynamic>? user = await fetchUserDataByEmail(email);
    Map<String, dynamic>? currentUser =
        await fetchUserDataByEmail(currentUserEmail!);
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    String idNoti = _generateRandom6DigitId();
    Map<String, dynamic> notiData = {
      'owner': currentUser,
      'id': idNoti,
      'user': user!,
      'room': widget.room
          .toJson(), // Số lượng câu hỏi, có thể thiết lập tĩnh hoặc lấy từ dữ liệu
    };
    DocumentReference notiRef =
        FirebaseFirestore.instance.collection('notifications').doc(idNoti);
    notiRef.set(notiData);
  }

  inviteUserId(userId) async {
    Map<String, dynamic>? user = await fetchUserDataByEmail(userId);

    String idNoti = _generateRandom6DigitId();
    Map<String, dynamic> notiData = {
      'id': idNoti,
      'user': user!,
      'room': widget.room
          .toJson(), // Số lượng câu hỏi, có thể thiết lập tĩnh hoặc lấy từ dữ liệu
    };
    DocumentReference notiRef =
        FirebaseFirestore.instance.collection('notifications').doc(idNoti);
    notiRef.set(notiData);
  }

  String _generateRandom6DigitId() {
    Random random = Random();
    int randomNumber =
        random.nextInt(900000) + 100000; // Tạo số trong khoảng 100000-999999
    return randomNumber.toString();
  }

  Future<Map<String, dynamic>?> fetchUserDataByEmail(String email) async {
    try {
      // Sử dụng where để lọc tài liệu theo email
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Lấy tài liệu đầu tiên phù hợp với email
        DocumentSnapshot userDoc = querySnapshot.docs.first;

        // Lấy dữ liệu người dùng dưới dạng Map
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          print('User data: $userData');
          return userData;
          // Thực hiện các xử lý khác với dữ liệu user ở đây
        }
      } else {
        print('No user found with email: $email');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }
}

class CustomTile extends StatelessWidget {
  const CustomTile({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${label}: ',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ],
    );
  }
}
