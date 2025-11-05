import 'package:flutter/material.dart';

enum MessageType { info, success, error, warning }

// Function to show custom messages using SnackBar
void showMessageBox(BuildContext context, String text, MessageType type) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: type == MessageType.success
          ? Colors.green[600]
          : type == MessageType.error
          ? Colors.red[600]
          : Colors.blue[600],
      duration: const Duration(seconds: 5),
    ),
  );
}
