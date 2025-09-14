import 'dart:convert';
import 'package:arena_teknoloji/stock_form.dart';
import 'package:arena_teknoloji/stock_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 🔹 globalCurrency main.dart içinde tanımlı
import 'main.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

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
  final _compatSearchCtrl = TextEditingController();

  bool loading = false;
  List allProducts = [];
  List searchResults = [];
  List compatibles = [];
  List variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl = TextEditingController(text: p["sku"]);
    _nameCtrl = TextEditingController(text: p["name"]);
    _barcodeCtrl = TextEditingController(text: p["barcode"] ?? "");

    _fetchCompatibles();
    _fetchAllProducts();
    _fetchVariants();

    _compatSearchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
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
          setState(() => compatibles = data);
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
        setState(() => allProducts = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("Tüm ürünler alınamadı: $e");
    }
  }

  Future<void> _fetchVariants() async {
    try {
      final res = await http.get(
        Uri.parse("$API_BASE/products/${widget.product["id"]}/stock"),
      );
      if (res.statusCode == 200) {
        setState(() {
          variants = jsonDecode(res.body);
        });
      } else {
        debugPrint("Varyant stokları alınamadı: ${res.body}");
      }
    } catch (e) {
      debugPrint("Varyant stokları alınamadı: $e");
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
      "unit": "adet",
      "is_active": 1,
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

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        _actionButton(
          icon: Icons.update,
          color: Colors.blue,
          label: "Güncelle",
          onTap: updateProduct,
        ),
        _actionButton(
          icon: Icons.delete,
          color: Colors.red,
          label: "Sil",
          onTap: deleteProduct,
        ),
        _actionButton(
          icon: Icons.list,
          color: Colors.orange,
          label: "Stoklar",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockListPage(product: widget.product),
              ),
            );
          },
        ),
        _actionButton(
          icon: Icons.add,
          color: Colors.green,
          label: "Stok Ekle",
          onTap: () async {
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
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color, // ✅ arka plan direkt renk
            foregroundColor: Colors.white, // ✅ yazılar her zaman beyaz
            minimumSize: const Size(0, 45), // ✅ yükseklik kontrolü
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 2,
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14, // ✅ font büyüklüğü
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _variantsTable() {
    if (variants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("Bu ürün için stok hareketi bulunmuyor."),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Varyantlar")),
          DataColumn(label: Text("Stok")),
          DataColumn(label: Text("Para Birimi")),
        ],
        rows: variants.map((v) {
          final varMap = v["variants"] ?? {};
          final varText = varMap.entries
              .map((e) => "${e.key}: ${e.value}")
              .join(", ");

          return DataRow(
            cells: [
              DataCell(Text(varText)),
              DataCell(Text(v["stock"].toString())),
              DataCell(Text(v["currency"].toString())),
            ],
          );
        }).toList(),
      ),
    );
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
            const SizedBox(height: 16),

            // 🔹 Uyumlu modeller
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

            const SizedBox(height: 16),
            _actionButtons(context),
            const SizedBox(height: 20),
            Text("Stok Durumu", style: Theme.of(context).textTheme.titleMedium),
            _variantsTable(),
          ],
        ),
      ),
    );
  }
}
