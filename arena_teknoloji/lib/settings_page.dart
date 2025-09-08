import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _currency;
  final List<String> currencies = ["TRY", "USD", "EUR"];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final res = await http.get(Uri.parse("$API_BASE/settings"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _currency = data["currency"] ?? "TRY";
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _saveCurrency(String value) async {
    setState(() => loading = true);
    final res = await http.put(
      Uri.parse("$API_BASE/settings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"key": "currency", "value": value}),
    );
    setState(() => loading = false);

    if (res.statusCode == 200) {
      setState(() => _currency = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Para birimi $value olarak kaydedildi")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${res.statusCode}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Ayarlar")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                    value: _currency,
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _saveCurrency(val);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
