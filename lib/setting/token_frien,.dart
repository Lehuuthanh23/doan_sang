// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:game_do_vui/screen/token_frien.dart';
// import 'package:game_do_vui/setting/bottom_item.dart';


// class MainScreen extends StatefulWidget {
//   @override
//   _MainScreenState createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int _selectedIndex = 0; // Assuming this is your navigation index
//   int _friendRequestCount = 0; // Initialize your friend request count

//   @override
//   void initState() {
//     super.initState();
//     _fetchFriendRequestCount(); // Fetch the initial count
//   }

//   Future<void> _fetchFriendRequestCount() async {
//     // Your logic to fetch the count from Firestore
//     String uid = FirebaseAuth.instance.currentUser!.uid;
//     QuerySnapshot friendRequests = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('friendRequests')
//         .where('status', isEqualTo: 'pending')
//         .get();

//     setState(() {
//       _friendRequestCount = friendRequests.docs.length; // Update the count
//     });
//   }

//   void _onNavBarTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Your AppBar and body setup
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: _selectedIndex,
//         onTap: _onNavBarTapped,
//         friendRequestCount: _friendRequestCount, // Pass the count here
//       ),
//     );
//   }
// }
