import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class CriticalListPage extends StatefulWidget {
  const CriticalListPage({super.key});

  @override
  State<CriticalListPage> createState() => _CriticalListPageState();
}

class _CriticalListPageState extends State<CriticalListPage> {
  List criticalProducts = [];
  List outOfStockProducts = [];
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
      final List allProducts = jsonDecode(res.body);

      // 🔹 Gruplama
      criticalProducts = [];
      outOfStockProducts = [];

      for (final p in allProducts) {
        final stock = double.tryParse(p["stock_on_hand"].toString()) ?? 0;
        final critical = double.tryParse(p["critical_stock"].toString()) ?? 0;

        if (stock <= 0) {
          outOfStockProducts.add(p);
        } else if (stock <= critical) {
          criticalProducts.add(p);
        }
      }

      setState(() => loading = false);
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${res.statusCode}")));
    }
  }

  Widget _buildProductTile(Map p, {bool outOfStock = false}) {
    final stock = numFmt.format(
      double.tryParse(p["stock_on_hand"].toString()) ?? 0,
    );
    final critical = numFmt.format(
      double.tryParse(p["critical_stock"].toString()) ?? 0,
    );
    final cost = numFmt.format(double.tryParse(p["avg_cost"].toString()) ?? 0);

    return ListTile(
      leading: Icon(
        outOfStock ? Icons.block : Icons.warning,
        color: outOfStock ? Colors.grey : Colors.red,
      ),
      title: Text(p["name"] ?? ""),
      subtitle: outOfStock
          ? Text("Stok: 0 • Maliyet: $cost ₺")
          : Text("Stok: $stock / Kritik: $critical • Maliyet: $cost ₺"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stok Durumu")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (criticalProducts.isEmpty && outOfStockProducts.isEmpty)
          ? const Center(child: Text("Tüm stoklar yeterli 🎉"))
          : ListView(
              children: [
                // 🔹 Kritik stoklar
                if (criticalProducts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Kritik Stoklar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...criticalProducts.map((p) => _buildProductTile(p)),
                  const Divider(),
                ],

                // 🔹 Stokta biten ürünler
                if (outOfStockProducts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Stokta Bitenler",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...outOfStockProducts.map(
                    (p) => _buildProductTile(p, outOfStock: true),
                  ),
                ],
              ],
            ),
    );
  }
}
