import 'package:flutter/material.dart';

class Adminpage extends StatefulWidget {
  const Adminpage({super.key});

  @override
  State<Adminpage> createState() => _AdminPageState();
}

class _AdminPageState extends State<Adminpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Page')),
      backgroundColor: const Color(0xFFFFF5CC),
      body: Center(child: Text('Welcome to the Admin Page')),
    );
  }
}
