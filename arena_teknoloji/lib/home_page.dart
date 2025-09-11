import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ const kaldırıldı
        title: const Text("Ana Sayfa"), // sadece Text const olabilir
      ),
      body: const Center(
        child: Text(
          "Arena Teknoloji Yönetim Paneli\nHoş Geldiniz 👋",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
