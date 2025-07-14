import 'package:flutter/material.dart';

enum MessageType { info, success, error }

class MessageBox extends StatefulWidget {
  const MessageBox({super.key});

  @override
  State<MessageBox> createState() => MessageBoxState();
}

class MessageBoxState extends State<MessageBox> {
  OverlayEntry? _overlayEntry;

  void showMessage(String message, MessageType type) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(type),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(color: _getTextColor(type), fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 5), () {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green.shade100;
      case MessageType.error:
        return Colors.red.shade100;
      case MessageType.info:
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getTextColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green.shade800;
      case MessageType.error:
        return Colors.red.shade800;
      case MessageType.info:
      default:
        return Colors.blue.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // This widget itself doesn't render anything visible directly
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
