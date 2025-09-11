import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'config.dart' as cfg;
import 'product_detail.dart';
import 'product_form.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  List filteredProducts = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _searchCtrl.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("${cfg.API_BASE}/products"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        products = data;
        filteredProducts = data;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void _filterProducts() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) {
        final name = (p["name"] ?? "").toString().toLowerCase();
        final barcode = (p["barcode"] ?? "").toString().toLowerCase();
        return name.contains(query) || barcode.contains(query);
      }).toList();
    });
  }

  Future<void> _confirmAndDelete(Map p) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: Text("${p["name"]} ürününü silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final id = p["id"].toString();
      final url = "${cfg.API_BASE}/products/$id";
      final res = await http.delete(Uri.parse(url));
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          products.removeWhere((e) => e["id"].toString() == id);
          filteredProducts.removeWhere((e) => e["id"].toString() == id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${p["name"]} silindi ✅")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme hatası: ${res.statusCode}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ürünler")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Arama
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Ürün ara (isim veya barkod)...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // 📋 Tablo görünümü
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DataTable(
                        columnSpacing: 20,
                        showBottomBorder: true,
                        columns: const [
                          DataColumn(label: Text("Ürün Adı")),
                          DataColumn(label: Text("Stok")),
                          DataColumn(label: Text("Durum")),
                          DataColumn(label: Text("Satış Fiyatı")),
                          DataColumn(label: Text("Maliyet")),
                          DataColumn(label: Text("Sil")),
                        ],
                        rows: filteredProducts.map((p) {
                          final stock =
                              double.tryParse(p["stock_on_hand"].toString()) ??
                              0;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(p["name"] ?? ""),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/productDetail',
                                    arguments: p,
                                  );
                                  if (result == true) fetchProducts();
                                },
                              ),
                              DataCell(Text(numFmt.format(stock))),
                              DataCell(
                                stock > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "Stokta Var",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "Stokta Yok",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                              ),
                              DataCell(
                                Text(
                                  "${numFmt.format(double.tryParse(p["sale_price"].toString()) ?? 0)} ${cfg.globalCurrency}",
                                ),
                              ),
                              DataCell(
                                Text(
                                  "${numFmt.format(double.tryParse(p["avg_cost"].toString()) ?? 0)} ${cfg.globalCurrency}",
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmAndDelete(p),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/productForm');
          if (result == true) fetchProducts();
        },
      ),
    );
  }
}
