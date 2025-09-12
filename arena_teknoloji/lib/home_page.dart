import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // ✅ Logo
            Image(
              image: AssetImage("assets/images/Splash.png"),
              width: 320, // ihtiyacına göre boyutunu ayarlayabilirsin
              height: 320,
            ),
            SizedBox(height: 24),
            Text(
              "Arena Teknoloji Yönetim Paneli\nHoş Geldiniz 👋",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
