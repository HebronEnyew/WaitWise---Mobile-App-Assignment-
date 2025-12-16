import 'package:flutter/material.dart';
import 'package:wait_wise/pages/homepage.dart';
import 'package:wait_wise/pages/servicepage.dart';
import 'package:wait_wise/pages/loginpage.dart';
import 'package:wait_wise/pages/adminpage.dart';
//kal

import 'package:wait_wise/pages/registerPage.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) => HomePage(),
        "/service": (context) => ServicePage(), //kal
        "/register": (context) => const RegisterPage(serviceName: ""),
        "/loginpage": (context) => const LoginPage(), //heb
        "/adminpage": (context) => const Adminpage(),
      },
    );
  }
}
