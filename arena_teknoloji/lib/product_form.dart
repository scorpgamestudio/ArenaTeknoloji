import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

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
  final _versionCtrl = TextEditingController();

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
      "unit": "adet",
      "category": selectedCategoryId,
      "brand": selectedBrandId,
      "model_id": selectedModelId,

      if (_skuCtrl.text.trim().isNotEmpty) "sku": _skuCtrl.text.trim(),
      if (_versionCtrl.text.trim().isNotEmpty)
        "version_code": _versionCtrl.text.trim(),
      // ❌ fiyat ve renk yok, varyant backend açacak
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
        debugPrint("❌ Response: ${res.body}");
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

  // ====== POPUP: Kategori Ekle (üst kategori + varyant seçenekleri) ======
  Future<void> _openAddCategoryDialog() async {
    final nameCtrl = TextEditingController();
    int? parentId;
    final selectedVariants = <String>{};

    // sabit varyant listesi
    const variantOptions = {
      "Renk": "Ürün renk seçeneği (siyah, beyaz, mavi vb.)",
      "Kasalı": "Ürün kasa ile birlikte gelir mi?",
      "Çıtalı": "Ekran çerçeveli mi?",
      "Ekran Teknolojisi": "TFT, INCELL, OLED gibi ekran tipleri",
      "Marka Adı": "Ürünün tedarik markası, boş ise OEM yazılır",
      "Batarya Tipi": "Standart veya Güçlendirilmiş",
      "Kapak Türü": "Kamera camlı veya düz kapak",
      "Durumu": "Sıfır Orjinal, Çıkma Orjinal vb.",
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Kategori Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Kategori Adı",
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: "Üst Kategori (opsiyonel)",
                      ),
                      value: parentId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Yok"),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem<int?>(
                            value: int.tryParse(c["id"].toString()),
                            child: Text(c["name"]),
                          ),
                        ),
                      ],
                      onChanged: (val) => parentId = val,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Varyant Seçenekleri",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: variantOptions.entries.map((entry) {
                        final opt = entry.key;
                        final desc = entry.value;
                        final checked = selectedVariants.contains(opt);
                        return FilterChip(
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                opt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          selected: checked,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (val) {
                                selectedVariants.add(opt);
                              } else {
                                selectedVariants.remove(opt);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                        "variant_options": selectedVariants.toList(),
                      }),
                    );
                    if (res.statusCode == 200 || res.statusCode == 201) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) _fetchDefinitions();
  }

  // ====== POPUP: Marka Ekle ======
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

  // ====== POPUP: Model Ekle (seçili markayı göstererek) ======
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
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (ok == true) _fetchDefinitions();
  }

  @override
  Widget build(BuildContext context) {
    final filteredModels = selectedBrandId == null
        ? <dynamic>[]
        : models.where(
            (m) => m["brand_id"].toString() == selectedBrandId.toString(),
          );

    // 🔹 Seçilen kategoriye bağlı varyantları çöz
    final selectedCategory = categories.firstWhere(
      (c) => c["id"].toString() == selectedCategoryId.toString(),
      orElse: () => {"variant_options": []},
    );
    List<dynamic> categoryVariants = [];
    if (selectedCategory["variant_options"] != null) {
      try {
        categoryVariants = selectedCategory["variant_options"] is String
            ? jsonDecode(selectedCategory["variant_options"])
            : (selectedCategory["variant_options"] as List);
      } catch (e) {
        debugPrint("Kategori varyant decode hatası: $e");
      }
    }

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

              // 🔹 Kategori - Marka - Model YAN YANA + Ekle butonları
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

              // 🔹 Bilgilendirme kutusu
              if (categoryVariants.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bilgilendirme",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bu ürün için stok hareketi girerken aşağıdaki varyasyonları "
                        "seçeceksiniz:",
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: categoryVariants
                            .map<Widget>(
                              (opt) => Chip(
                                label: Text(opt.toString()),
                                backgroundColor: Colors.green.shade100,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
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
