import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:collection/collection.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

// 🔹 14 sabit renk listesi
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

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _skuCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _criticalCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _compatSearchCtrl = TextEditingController();

  final Set<String> _selectedColors = {};
  final Set<Map<String, dynamic>> _selectedCompatibles = {};

  List allProducts = [];
  List searchResults = [];
  List categories = [];
  List brands = [];
  List models = [];

  int? selectedCategoryId;
  int? selectedBrandId;
  int? selectedModelId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchDefinitions();
    _compatSearchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _fetchDefinitions() async {
    try {
      final catRes = await http.get(Uri.parse("$API_BASE/categories"));
      final brandRes = await http.get(Uri.parse("$API_BASE/brands"));
      final modelRes = await http.get(Uri.parse("$API_BASE/models"));

      if (catRes.statusCode == 200) categories = jsonDecode(catRes.body);
      if (brandRes.statusCode == 200) brands = jsonDecode(brandRes.body);
      if (modelRes.statusCode == 200) models = jsonDecode(modelRes.body);

      setState(() {});
    } catch (e) {
      debugPrint("Tanımlar alınamadı: $e");
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchaseCtrl.dispose();
    _saleCtrl.dispose();
    _criticalCtrl.dispose();
    _versionCtrl.dispose();
    _compatSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await http.get(Uri.parse("$API_BASE/products"));
      if (res.statusCode == 200) {
        setState(() {
          allProducts = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Ürün listesi alınamadı: $e");
    }
  }

  void _onSearchChanged() {
    final query = _compatSearchCtrl.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    setState(() {
      searchResults = allProducts
          .where((p) => (p["name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  // 🔹 Boşsa otomatik barkod (EAN-13)
  String _genEAN13() {
    final rnd = Random();
    final digits = [8, 6, 9];
    for (int i = 0; i < 9; i++) {
      digits.add(rnd.nextInt(10));
    }
    int sumOdd = 0, sumEven = 0;
    for (int i = 0; i < 12; i++) {
      if ((i + 1) % 2 == 0) {
        sumEven += digits[i];
      } else {
        sumOdd += digits[i];
      }
    }
    final total = sumOdd + sumEven * 3;
    final check = (10 - (total % 10)) % 10;
    digits.add(check);
    return digits.join();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final barcode = _barcodeCtrl.text.trim().isEmpty
        ? _genEAN13()
        : _barcodeCtrl.text.trim();

    final body = {
      "barcode": barcode,
      "name": _nameCtrl.text.trim(),
      "purchase_price":
          double.tryParse(_purchaseCtrl.text.replaceAll(",", ".")) ?? 0,
      "sale_price":
          double.tryParse(_saleCtrl.text.replaceAll(",", ".")) ?? 0,
      "critical_stock":
          double.tryParse(_criticalCtrl.text.replaceAll(",", ".")) ?? 0,
      "unit": "adet",
      "category": selectedCategoryId,
      "brand": selectedBrandId,
      "model": selectedModelId,
      if (_skuCtrl.text.trim().isNotEmpty) "sku": _skuCtrl.text.trim(),
      if (_versionCtrl.text.trim().isNotEmpty)
        "version_code": _versionCtrl.text.trim(),
      if (_selectedColors.isNotEmpty) "colors": _selectedColors.toList(),
    };

    try {
      final res = await http.post(
        Uri.parse("$API_BASE/products"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        final productId = jsonDecode(res.body)["id"];

        // 🔹 Uyumlu modelleri kaydet
        if (_selectedCompatibles.isNotEmpty) {
          final ids = _selectedCompatibles
              .map((p) => int.tryParse(p["id"].toString()) ?? 0)
              .where((id) => id > 0)
              .toList();

          await http.post(
            Uri.parse("$API_BASE/products/$productId/compatibles"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"compatibles": ids}),
          );
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata ${res.statusCode}: ${res.body}")),
        );
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("İstek başarısız: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Yeni Ürün")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: "SKU (opsiyonel)"),
            ),

            // 🔹 Kategori Autocomplete
         // 🔹 Kategori Autocomplete
Autocomplete<Map<String, dynamic>>(
  displayStringForOption: (opt) => opt["name"] ?? "",
  optionsBuilder: (TextEditingValue text) {
    if (text.text.isEmpty) {
      return categories.cast<Map<String, dynamic>>();
    }
    return categories
        .where((c) =>
            (c["name"] ?? "").toLowerCase().contains(text.text.toLowerCase()))
        .cast<Map<String, dynamic>>(); // ✅ tip dönüştürme
  },
  onSelected: (val) {
    setState(() {
      selectedCategoryId = int.tryParse(val["id"].toString());
    });
  },
  fieldViewBuilder: (ctx, controller, node, onComplete) {
    return TextFormField(
      controller: controller,
      focusNode: node,
      decoration: const InputDecoration(
        labelText: "Kategori",
        border: OutlineInputBorder(),
      ),
      validator: (_) =>
          selectedCategoryId == null ? "Kategori seçmek zorunlu" : null,
    );
  },
),

            const SizedBox(height: 12),

            // 🔹 Marka Autocomplete
            // 🔹 Marka Autocomplete
Autocomplete<Map<String, dynamic>>(
  displayStringForOption: (opt) => opt["name"] ?? "",
  optionsBuilder: (TextEditingValue text) {
    if (text.text.isEmpty) {
      return brands.cast<Map<String, dynamic>>();
    }
    return brands
        .where((b) =>
            (b["name"] ?? "").toLowerCase().contains(text.text.toLowerCase()))
        .cast<Map<String, dynamic>>();
  },
  onSelected: (val) {
    setState(() {
      selectedBrandId = int.tryParse(val["id"].toString());
    });
  },
  fieldViewBuilder: (ctx, controller, node, onComplete) {
    return TextFormField(
      controller: controller,
      focusNode: node,
      decoration: const InputDecoration(
        labelText: "Marka",
        border: OutlineInputBorder(),
      ),
      validator: (_) =>
          selectedBrandId == null ? "Marka seçmek zorunlu" : null,
    );
  },
),

            const SizedBox(height: 12),

            // 🔹 Model Autocomplete
           // 🔹 Model Autocomplete
Autocomplete<Map<String, dynamic>>(
  displayStringForOption: (opt) =>
      "${opt["name"] ?? ""} (${opt["brand_name"] ?? ""})",
  optionsBuilder: (TextEditingValue text) {
    if (text.text.isEmpty) {
      return models.cast<Map<String, dynamic>>();
    }
    return models
        .where((m) =>
            (m["name"] ?? "").toLowerCase().contains(text.text.toLowerCase()))
        .cast<Map<String, dynamic>>();
  },
  onSelected: (val) {
    setState(() {
      selectedModelId = int.tryParse(val["id"].toString());
    });
  },
  fieldViewBuilder: (ctx, controller, node, onComplete) {
    return TextFormField(
      controller: controller,
      focusNode: node,
      decoration: const InputDecoration(
        labelText: "Model",
        border: OutlineInputBorder(),
      ),
      validator: (_) =>
          selectedModelId == null ? "Model seçmek zorunlu" : null,
    );
  },
),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Ürün Adı"),
              validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Barkod (boşsa otomatik)",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _barcodeCtrl.text = _genEAN13();
                    setState(() {});
                  },
                  child: const Text("Oluştur"),
                ),
              ],
            ),
            TextFormField(
              controller: _versionCtrl,
              decoration:
                  const InputDecoration(labelText: "Versiyon Kodu (opsiyonel)"),
            ),
            TextFormField(
              controller: _purchaseCtrl,
              decoration: const InputDecoration(labelText: "Alış Fiyatı"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _saleCtrl,
              decoration: const InputDecoration(labelText: "Satış Fiyatı"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _criticalCtrl,
              decoration: const InputDecoration(labelText: "Kritik Stok"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            Text("Renkler", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: predefinedColors.map((color) {
                final checked = _selectedColors.contains(color);
                return FilterChip(
                  label: Text(color),
                  selected: checked,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedColors.add(color);
                      } else {
                        _selectedColors.remove(color);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Text("Uyumlu Modeller",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
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
                final id = int.tryParse(p["id"].toString()) ?? 0;
                return ListTile(
                  title: Text(p["name"] ?? ""),
                  trailing: IconButton(
                    icon: Icon(
                      _selectedCompatibles.any((x) => x["id"] == id)
                          ? Icons.check_box
                          : Icons.add_box_outlined,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_selectedCompatibles.any((x) => x["id"] == id)) {
                          _selectedCompatibles.removeWhere((x) => x["id"] == id);
                        } else {
                          _selectedCompatibles.add(p);
                        }
                      });
                    },
                  ),
                );
              }),

            if (_selectedCompatibles.isNotEmpty) ...[
              const Divider(),
              Text("Seçilen Modeller",
                  style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 6,
                children: _selectedCompatibles.map((p) {
                  return Chip(
                    label: Text(p["name"] ?? ""),
                    onDeleted: () {
                      setState(() {
                        _selectedCompatibles
                            .removeWhere((x) => x["id"] == p["id"]);
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Kaydet"),
            ),
          ],
        ),
      ),
    ),
  );
}

}
