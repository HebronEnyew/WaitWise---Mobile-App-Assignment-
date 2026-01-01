import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wait_wise/pages/homepage.dart';
import 'package:wait_wise/pages/servicepage.dart';
import 'package:wait_wise/pages/loginpage.dart';
import 'package:wait_wise/pages/adminpage.dart';
import 'package:wait_wise/pages/registerPage.dart';
import 'package:wait_wise/pages/user_login_page.dart';
import 'package:wait_wise/services/supabase_service.dart';
import 'package:wait_wise/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    await SupabaseService.instance.init();
  } catch (e) {
    print('Supabase initialization error: $e');
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) => const HomePage(),
        "/service": (context) => const ServicePage(),
        "/register": (context) => const RegisterPage(serviceName: ""),
        "/loginpage": (context) => const LoginPage(),
        "/adminpage": (context) => const Adminpage(serviceName: ""),
        "/userlogin": (context) => const UserLoginPage(),
      },
    );
  }
}
