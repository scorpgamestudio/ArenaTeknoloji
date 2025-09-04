import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE = "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class StockListPage extends StatefulWidget {
  final Map product;
  const StockListPage({super.key, required this.product});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  List movements = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");

  @override
  void initState() {
    super.initState();
    fetchMovements();
  }

  Future<void> fetchMovements() async {
    final res = await http.get(
      Uri.parse("$API_BASE/products/${widget.product["id"]}/stock"),
    );
    if (res.statusCode == 200) {
      setState(() {
        movements = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stok Hareketleri: ${widget.product["name"]}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : movements.isEmpty
          ? const Center(child: Text("Henüz hareket yok"))
          : ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final m = movements[index];

                final qty = numFmt.format(
                  double.tryParse(m["qty"].toString()) ?? 0,
                );
                final price = numFmt.format(
                  double.tryParse(m["unit_price"].toString()) ?? 0,
                );

                return ListTile(
                  title: Text(
                    "${m["type"] == "in" ? "Giriş" : "Çıkış"} • $qty adet • $price ₺",
                  ),
                  subtitle: Text(
                    "Tedarikçi: ${m["supplier_name"] ?? "-"} • Tarih: ${m["created_at"]}",
                  ),
                );
              },
            ),
    );
  }
}
