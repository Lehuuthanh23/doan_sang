class Room {
  Room(
      {required this.id,
      required this.password,
      required this.users,
      required this.topicId,
      required this.questionCount,
      required this.isPlaying,
      required this.isStarted});

  String id;
  String password;
  String topicId;
  List<String> users;
  String questionCount;
  bool isPlaying;
  bool isStarted;
  // Phương thức fromJson để khởi tạo Room từ Map
  factory Room.fromJson(Map<String, dynamic> json) {
    print(json);
    return Room(
      id: json['id'],

      password: json['password'],
      topicId: json['topicId'],
      users: List<String>.from(json['users']),
      questionCount: json['questionCount'],
      isStarted: json["isStarted"],
      isPlaying: json["isPlaying"],
    );
  }

  // Phương thức toJson để chuyển Room thành Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'topicId': topicId,
      'users': users,
      'questionCount': questionCount,
      'isStarted': isStarted,
      'isPlaying': isPlaying
    };
  }
}
