import 'dart:convert';
import 'package:arena_teknoloji/stock_form.dart';
import 'package:arena_teknoloji/stock_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// 🔹 globalCurrency değişkeni main.dart içinde tanımlı
import 'main.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

const predefinedColors = [
  "Siyah",
  "Beyaz",
  "Mavi",
  "Gold",
  "Silver",
  "Violet",
  "Mor",
  "Çöl Rengi",
  "Kırmızı",
  "Yeşil",
  "Turuncu",
  "Pembe",
  "Sarı",
  "Turkuaz",
];

class ProductDetailPage extends StatefulWidget {
  final Map product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController _skuCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _purchaseCtrl;
  late TextEditingController _saleCtrl;
  late TextEditingController _criticalCtrl;
  final _compatSearchCtrl = TextEditingController();

  final numFmt = NumberFormat("#,##0.##", "tr_TR");
  bool loading = false;

  Set<String> selectedColors = {};
  List allProducts = [];
  List searchResults = [];
  List compatibles = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl = TextEditingController(text: p["sku"]);
    _nameCtrl = TextEditingController(text: p["name"]);
    _barcodeCtrl = TextEditingController(text: p["barcode"] ?? "");
    _purchaseCtrl = TextEditingController(
      text: p["purchase_price"]?.toString() ?? "0",
    );
    _saleCtrl = TextEditingController(text: p["sale_price"]?.toString() ?? "0");
    _criticalCtrl = TextEditingController(
      text: p["critical_stock"]?.toString() ?? "0",
    );

    if (p["colors"] is List) {
      selectedColors = Set<String>.from(p["colors"]);
    }
    _fetchCompatibles();
    _fetchAllProducts();

    _compatSearchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchaseCtrl.dispose();
    _saleCtrl.dispose();
    _criticalCtrl.dispose();
    _compatSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompatibles() async {
    try {
      final res = await http.get(
        Uri.parse("$API_BASE/products/${widget.product["id"]}/compatibles"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            compatibles = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Uyumlu modeller alınamadı: $e");
    }
  }

  Future<void> _fetchAllProducts() async {
    try {
      final res = await http.get(Uri.parse("$API_BASE/products"));
      if (res.statusCode == 200) {
        setState(() {
          allProducts = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Tüm ürünler alınamadı: $e");
    }
  }

  void _onSearchChanged() {
    final q = _compatSearchCtrl.text.toLowerCase();
    if (q.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    setState(() {
      searchResults = allProducts
          .where(
            (p) =>
                (p["name"] ?? "").toString().toLowerCase().contains(q) &&
                p["id"].toString() != widget.product["id"].toString(),
          )
          .toList();
    });
  }

  Future<void> updateProduct() async {
    setState(() => loading = true);

    final body = {
      "sku": _skuCtrl.text,
      "barcode": _barcodeCtrl.text,
      "name": _nameCtrl.text,
      "purchase_price": double.tryParse(_purchaseCtrl.text) ?? 0,
      "sale_price": double.tryParse(_saleCtrl.text) ?? 0,
      "critical_stock": double.tryParse(_criticalCtrl.text) ?? 0,
      "unit": "adet",
      "is_active": 1,
      "colors": selectedColors.toList(),
    };

    final res = await http.put(
      Uri.parse("$API_BASE/products/${widget.product["id"]}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final ids = compatibles.map((c) => c["id"]).toList();
      await http.post(
        Uri.parse("$API_BASE/products/${widget.product["id"]}/compatibles"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"compatibles": ids}),
      );

      if (context.mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata ${res.statusCode} - ${res.body}")),
      );
    }
    setState(() => loading = false);
  }

  Future<void> deleteProduct() async {
    setState(() => loading = true);
    final res = await http.delete(
      Uri.parse("$API_BASE/products/${widget.product["id"]}"),
    );
    setState(() => loading = false);
    if (res.statusCode == 200) {
      if (context.mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${res.statusCode} - ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ürün Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: "SKU"),
            ),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Ürün Adı"),
            ),
            TextField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(labelText: "Barkod"),
            ),
            TextField(
              controller: _purchaseCtrl,
              decoration: InputDecoration(
                labelText: "Alış Fiyatı ($globalCurrency)",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _saleCtrl,
              decoration: InputDecoration(
                labelText: "Satış Fiyatı ($globalCurrency)",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _criticalCtrl,
              decoration: const InputDecoration(labelText: "Kritik Stok"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            Text("Renkler", style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 6,
              children: predefinedColors.map((c) {
                final selected = selectedColors.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        selectedColors.add(c);
                      } else {
                        selectedColors.remove(c);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            Text(
              "Uyumlu Modeller",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              controller: _compatSearchCtrl,
              decoration: const InputDecoration(
                labelText: "Ürün ara...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            if (searchResults.isNotEmpty)
              ...searchResults.take(5).map((p) {
                final exists = compatibles.any((x) => x["id"] == p["id"]);
                return ListTile(
                  title: Text(p["name"] ?? ""),
                  trailing: IconButton(
                    icon: Icon(
                      exists ? Icons.check_box : Icons.add_box_outlined,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (exists) {
                          compatibles.removeWhere((x) => x["id"] == p["id"]);
                        } else {
                          compatibles.add(p);
                        }
                      });
                    },
                  ),
                );
              }),

            if (compatibles.isNotEmpty) ...[
              const Divider(),
              Text(
                "Seçilen Uyumlu Modeller",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 6,
                children: compatibles.map((p) {
                  return Chip(
                    label: Text(p["name"] ?? ""),
                    backgroundColor: Colors.orange.shade100,
                    onDeleted: () {
                      setState(() {
                        compatibles.removeWhere((x) => x["id"] == p["id"]);
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : updateProduct,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Güncelle"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: loading ? null : deleteProduct,
              child: const Text("Sil"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockListPage(product: widget.product),
                  ),
                );
              },
              child: const Text("Stok Hareketlerini Gör"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockFormPage(product: widget.product),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text("Stok Hareketi Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
