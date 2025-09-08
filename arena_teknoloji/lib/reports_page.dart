import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedReport = "capital"; // varsayılan sermaye raporu
  bool loading = false;
  double? totalCapital;

  Future<void> _fetchCapitalReport() async {
    setState(() {
      loading = true;
      totalCapital = null;
    });
    try {
      final res = await http.get(Uri.parse("$API_BASE/products"));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        double total = 0;
        for (final p in list) {
          final qty = double.tryParse(p["stock_on_hand"].toString()) ?? 0;
          final cost = double.tryParse(p["avg_cost"].toString()) ?? 0;
          total += qty * cost;
        }
        setState(() => totalCapital = total);
      } else {
        debugPrint("❌ Hata: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Raporlama")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text("Sermaye Raporu"),
                  selected: selectedReport == "capital",
                  onSelected: (_) {
                    setState(() => selectedReport = "capital");
                    _fetchCapitalReport();
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: loading
                    ? const CircularProgressIndicator()
                    : totalCapital == null
                    ? const Text("Sermaye raporu için seçim yapın")
                    : Text(
                        "💰 Toplam Sermaye: ${totalCapital!.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
