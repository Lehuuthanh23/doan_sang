import 'package:flutter/material.dart';
import 'package:game_do_vui/model/room.dart';

class ResultSoloDialog extends StatelessWidget {
  final int status; // Biến truyền vào để xác định trạng thái
  final Room room;
  final Map<String, dynamic> categories;
  final bool showAwait;
  const ResultSoloDialog(
      {super.key,
      required this.status,
      required this.room,
      required this.showAwait,
      required this.categories});

  @override
  Widget build(BuildContext context) {
    // Chọn thông báo và màu sắc dựa trên giá trị của status
    String message;
    Color backgroundColor;

    switch (status) {
      case 0:
        message = "Đang đợi người chơi khác";
        backgroundColor = Colors.orange;
        break;
      case 1:
        message = "Chiến thắng";
        backgroundColor = Colors.green;
        break;
      case 2:
        message = "Thua cuộc";
        backgroundColor = Colors.red;
        break;
      default:
        message = "Trạng thái không xác định";
        backgroundColor = Colors.grey;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (status != 0) {
                  if (showAwait) {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text("Đóng"),
            ),
          ],
        ),
      ),
    );
  }
}

// Hàm để mở dialog
void showResultSoloDialog(BuildContext context, int status, Room room,
    bool showAwait, Map<String, dynamic> categories) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return ResultSoloDialog(
        status: status,
        room: room,
        categories: categories,
        showAwait: showAwait,
      );
    },
  );
}
