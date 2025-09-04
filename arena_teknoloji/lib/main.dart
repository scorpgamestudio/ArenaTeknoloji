import 'dart:convert';
import 'package:arena_teknoloji/critical_list.dart';
import 'package:arena_teknoloji/product_detail.dart';
import 'package:arena_teknoloji/product_form.dart';
import 'package:arena_teknoloji/supplier_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE = "http://businessmanager.arenateknoloji.com";

void main() {
  runApp(const ArenaApp());
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena Teknoloji',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductListPage(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List products = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$API_BASE/products"));
    if (res.statusCode == 200) {
      setState(() {
        products = jsonDecode(res.body);
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
        title: const Text("Ürünler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: "Tedarikçiler",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupplierListPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.warning),
            tooltip: "Kritik Stok",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CriticalListPage()),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  title: Text(p["name"] ?? ""),
                  subtitle: Text(
                    "Stok: ${numFmt.format(double.tryParse(p["stock_on_hand"].toString()) ?? 0)}"
                    " | Satış: ${numFmt.format(double.tryParse(p["sale_price"].toString()) ?? 0)} ₺"
                    " | Maliyet: ${numFmt.format(double.tryParse(p["avg_cost"].toString()) ?? 0)} ₺",
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: p),
                      ),
                    );
                    if (result == true) {
                      fetchProducts(); // güncelleme/silmeden sonra liste yenile
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
          if (result == true) {
            fetchProducts(); // ürün eklenince listeyi yenile
          }
        },
      ),
    );
  }
}
