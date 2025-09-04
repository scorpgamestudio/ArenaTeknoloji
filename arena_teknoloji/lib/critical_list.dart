import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE = "http://businessmanager.arenateknoloji.com";

class CriticalListPage extends StatefulWidget {
  const CriticalListPage({super.key});

  @override
  State<CriticalListPage> createState() => _CriticalListPageState();
}

class _CriticalListPageState extends State<CriticalListPage> {
  List products = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");

  @override
  void initState() {
    super.initState();
    fetchCritical();
  }

  Future<void> fetchCritical() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$API_BASE/critical"));
    if (res.statusCode == 200) {
      setState(() {
        products = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${res.statusCode}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kritik Stoklar")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("Kritik stokta ürün yok 🎉"))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];

                // Sayıları formatla
                final stock = numFmt.format(
                  double.tryParse(p["stock_on_hand"].toString()) ?? 0,
                );
                final critical = numFmt.format(
                  double.tryParse(p["critical_stock"].toString()) ?? 0,
                );
                final cost = numFmt.format(
                  double.tryParse(p["avg_cost"].toString()) ?? 0,
                );

                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(p["name"] ?? ""),
                  subtitle: Text(
                    "Stok: $stock / Kritik: $critical • Maliyet: $cost ₺",
                  ),
                );
              },
            ),
    );
  }
}
