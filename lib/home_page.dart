import 'package:flutter/material.dart';
import 'location_page.dart';
import 'chatbot_page.dart'; // Make sure this file exists

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crime Locator"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Check Location Risk'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chatbot'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatbotPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("Check Location Risk"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LocationPage()),
            );
          },
        ),
      ),
    );
  }
}
