import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String zoneName;

  ChatScreen({required this.zoneName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(zoneName),
        backgroundColor: Colors.pink.shade900,
      ),
      body: Center(
        child: Text(
          'Welcome to $zoneName Chat!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
