import 'package:flutter/material.dart';

void main() {
  runApp(const GroApp());
}

class GroApp extends StatelessWidget {
  const GroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROAPP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('هنا ستظهر قائمة المنتجات قريباً!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // لاحقاً سنضع هنا كود فتح الكاميرا
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
