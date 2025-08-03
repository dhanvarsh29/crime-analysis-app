import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(CrimeApp());
}

class CrimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crime Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
    );
  }
}
