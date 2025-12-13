import 'package:flutter/material.dart';
import 'package:wait_wise/pages/homepage.dart';
import 'package:wait_wise/pages/servicepage.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) => HomePage(),
        "/service": (context) => ServicePage(),
      },
    );
  }
}
