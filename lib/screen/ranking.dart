import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankScreen extends StatefulWidget {
  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen>
    with SingleTickerProviderStateMixin {
  List<DocumentSnapshot> topSelfPracticePlayers = [];
  List<DocumentSnapshot> topDuelPlayers = [];
  bool isLoading = true;
  String errorMessage = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    loadTopPlayers();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> loadTopPlayers() async {
    try {
      List<DocumentSnapshot> selfPracticePlayers =
          await getTop10Players("Chơi tự luyện");
      List<DocumentSnapshot> duelPlayers =
          await getTop10Players("Chơi đối kháng");

      setState(() {
        topSelfPracticePlayers = selfPracticePlayers;
        topDuelPlayers = duelPlayers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  Future<List<DocumentSnapshot>> getTop10Players(String mode) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('playHistory')
        .where('mode', isEqualTo: mode)
        .orderBy('score', descending: true)
        .limit(10)
        .get();

    return querySnapshot.docs;
  }

  Future<String> getUsername(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists
        ? (userDoc.data() as Map<String, dynamic>)['username'] ?? 'Unknown User'
        : 'Unknown User';
  }

  Widget buildPlayerList(String title, List<DocumentSnapshot> players) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: FutureBuilder<List<Widget>>(
            future: Future.wait(players.map((player) async {
              String username = await getUsername(player['userId']);
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${players.indexOf(player) + 1}'),
                ),
                title: Text(username),
                trailing: Text('Điểm: ${player['score']}'),
              );
            }).toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return ListView(children: snapshot.data ?? []);
              }
            },
          ),
        ),
      ],
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
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Bảng xếp hạng',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 24),
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
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Chơi tự luyện'),
                          Tab(text: 'Chơi đối kháng'),
                        ],
                      ),
                      const SizedBox(height: 16), 

                      Expanded(
                        child: isLoading
                            ? Center(child: CircularProgressIndicator())
                            : errorMessage.isNotEmpty
                                ? Center(child: Text(errorMessage))
                                : TabBarView(
                                    controller: _tabController,
                                    children: [
                                      buildPlayerList("Chơi tự luyện",
                                          topSelfPracticePlayers),
                                      buildPlayerList(
                                          "Chơi đối kháng", topDuelPlayers),
                                    ],
                                  ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
