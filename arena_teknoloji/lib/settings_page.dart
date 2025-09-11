import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart' as cfg;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedCurrency = cfg.globalCurrency;
  final currencies = ["TRY", "USD", "EUR"];
  bool loading = false;

  Future<void> _saveCurrency() async {
    setState(() => loading = true);

    final res = await http.post(
      Uri.parse("${cfg.API_BASE}/settings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"currency": selectedCurrency}),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      cfg.globalCurrency = selectedCurrency; // 🔹 global değişken güncellensin
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Para birimi $selectedCurrency olarak kaydedildi"),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${res.statusCode}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Genel Para Birimi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedCurrency,
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedCurrency = val);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _saveCurrency,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
