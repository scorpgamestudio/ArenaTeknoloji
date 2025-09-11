import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  final Set<String> _selectedColors = {};
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
    _fetchDefinitions();
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
    super.dispose();
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
      "sale_price": double.tryParse(_saleCtrl.text.replaceAll(",", ".")) ?? 0,
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
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata ${res.statusCode}: ${res.body}")),
        );
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("İstek başarısız: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // ====== POPUP: Kategori Ekle (üst kategori seçilebilir) ======
  Future<void> _openAddCategoryDialog() async {
    final nameCtrl = TextEditingController();
    int? parentId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kategori Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Kategori Adı"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: "Üst Kategori (opsiyonel)",
                border: OutlineInputBorder(),
              ),
              value: parentId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("Yok")),
                ...categories.map<DropdownMenuItem<int?>>(
                  (c) => DropdownMenuItem<int?>(
                    value: int.tryParse(c["id"].toString()),
                    child: Text(c["name"]),
                  ),
                ),
              ],
              onChanged: (v) => parentId = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final res = await http.post(
                Uri.parse("$API_BASE/categories"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "name": name,
                  if (parentId != null) "parent_id": parentId,
                }),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (ok == true) _fetchDefinitions();
  }

  // ====== POPUP: Marka Ekle (bağımsız) ======
  Future<void> _openAddBrandDialog() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Marka Ekle"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Marka Adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final res = await http.post(
                Uri.parse("$API_BASE/brands"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"name": name}),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (ok == true) _fetchDefinitions();
  }

  // ====== POPUP: Model Ekle (markaya bağlı + üst model seçilebilir) ======
  Future<void> _openAddModelDialog() async {
    if (selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir marka seçmelisiniz")),
      );
      return;
    }

    final nameCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Model Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seçili Marka: ${brands.firstWhere((b) => b["id"].toString() == selectedBrandId.toString(), orElse: () => {"name": "-"})["name"]}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Model Adı"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final res = await http.post(
                Uri.parse("$API_BASE/models"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"name": name, "brand_id": selectedBrandId}),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Model eklenemedi (${res.statusCode})"),
                  ),
                );
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _fetchDefinitions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredModels = selectedBrandId == null
        ? <dynamic>[]
        : models.where(
            (m) => m["brand_id"].toString() == selectedBrandId.toString(),
          );

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
              const SizedBox(height: 12),

              // 🔹 Kategori - Marka - Model YAN YANA
              Row(
                children: [
                  // Kategori
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Kategori",
                            border: OutlineInputBorder(),
                          ),
                          value: selectedCategoryId,
                          hint: const Text("Kategori seç"),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: int.tryParse(c["id"].toString()),
                                  child: Text(c["name"]),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCategoryId = val;
                            });
                          },
                        ),
                        TextButton(
                          onPressed: _openAddCategoryDialog,
                          child: const Text("+ Kategori Ekle"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Marka
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Marka",
                            border: OutlineInputBorder(),
                          ),
                          value: selectedBrandId,
                          hint: const Text("Marka seç"),
                          items: brands
                              .map(
                                (b) => DropdownMenuItem<int>(
                                  value: int.tryParse(b["id"].toString()),
                                  child: Text(b["name"]),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedBrandId = val;
                              selectedModelId = null;
                            });
                          },
                        ),
                        TextButton(
                          onPressed: _openAddBrandDialog,
                          child: const Text("+ Marka Ekle"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Model
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Model",
                            border: OutlineInputBorder(),
                          ),
                          value: selectedModelId,
                          hint: const Text("Model seç"),
                          items: filteredModels
                              .map(
                                (m) => DropdownMenuItem<int>(
                                  value: int.tryParse(m["id"].toString()),
                                  child: Text(m["name"]),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => selectedModelId = val);
                          },
                        ),
                        TextButton(
                          onPressed: selectedBrandId == null
                              ? null
                              : _openAddModelDialog,
                          child: const Text("+ Model Ekle"),
                        ),
                      ],
                    ),
                  ),
                ],
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
                decoration: const InputDecoration(
                  labelText: "Versiyon Kodu (opsiyonel)",
                ),
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
