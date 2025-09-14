import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supplier_form.dart';

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

const ekranTeknolojileri = ["TFT", "INCELL", "OLED"];

class StockFormPage extends StatefulWidget {
  final Map product;
  const StockFormPage({super.key, required this.product});

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _brandNameCtrl = TextEditingController();

  String movementType = "in"; // varsayılan giriş
  bool loading = false;

  // Suppliers
  List suppliers = [];
  int? selectedSupplierId;
  bool loadingSuppliers = true;

  // Varyantlar
  List<String> categoryVariants = [];

  // Seçimler
  Set<String> selectedColors = {};
  String? selectedEkranTeknolojisi;
  String? markaAdi;

  // Currency
  String currency = "TRY";

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
    fetchCurrency();
    fetchVariants();
  }

  Future<void> fetchCurrency() async {
    try {
      final res = await http.get(Uri.parse("$API_BASE/settings"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          currency = data["currency"] ?? "TRY";
        });
      }
    } catch (e) {
      debugPrint("Para birimi alınamadı: $e");
    }
  }

  Future<void> fetchSuppliers() async {
    setState(() => loadingSuppliers = true);
    final res = await http.get(Uri.parse("$API_BASE/suppliers"));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      setState(() {
        suppliers = list;
        loadingSuppliers = false;
      });
    } else {
      setState(() => loadingSuppliers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tedarikçiler alınamadı: ${res.statusCode}")),
      );
    }
  }

  Future<void> fetchVariants() async {
    try {
      final catId = widget.product["category"];
      if (catId == null) return;

      final res = await http.get(Uri.parse("$API_BASE/categories"));
      if (res.statusCode == 200) {
        final cats = jsonDecode(res.body);
        final cat = cats.firstWhere(
          (c) => c["id"].toString() == catId.toString(),
          orElse: () => null,
        );

        if (cat != null && cat["variant_options"] != null) {
          List<dynamic> opts = [];
          try {
            opts = cat["variant_options"] is String
                ? jsonDecode(cat["variant_options"])
                : (cat["variant_options"] as List);
          } catch (e) {
            debugPrint("Varyant decode hatası: $e");
          }

          setState(() {
            categoryVariants = opts.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Kategori varyantları alınamadı: $e");
    }
  }

  Future<void> saveMovement() async {
    if (_qtyCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Miktar ve fiyat zorunlu")));
      return;
    }

    // Seçilen varyantları paketle
    final Map<String, dynamic> selectedVariantData = {};
    if (selectedColors.isNotEmpty) {
      selectedVariantData["Renk"] = selectedColors.toList();
    }
    if (_brandNameCtrl.text.trim().isNotEmpty) {
      selectedVariantData["Marka Adı"] = _brandNameCtrl.text.trim();
    }
    if (selectedEkranTeknolojisi != null) {
      selectedVariantData["Ekran Teknolojisi"] = selectedEkranTeknolojisi;
    }

    setState(() => loading = true);

    final body = {
      "product_id": widget.product["id"],
      "qty": double.tryParse(_qtyCtrl.text) ?? 0,
      "unit_price": double.tryParse(_priceCtrl.text) ?? 0,
      "type": movementType,
      "ref": "APP",
      "note": _noteCtrl.text,
      "supplier_id": selectedSupplierId,
      "variants": selectedVariantData, // JSON objesi olarak yolluyoruz
    };

    final res = await http.post(
      Uri.parse("$API_BASE/stock"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() => loading = false);

    if (res.statusCode == 201) {
      if (context.mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${res.statusCode} - ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierDropdown = loadingSuppliers
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<int>(
            value: selectedSupplierId,
            items: suppliers
                .map<DropdownMenuItem<int>>(
                  (s) => DropdownMenuItem<int>(
                    value: int.tryParse(s["id"].toString()),
                    child: Text(s["name"] ?? ""),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedSupplierId = v),
            decoration: const InputDecoration(
              labelText: "Tedarikçi (opsiyonel)",
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text("Stok Hareketi: ${widget.product["name"]}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Stok giriş/çıkış seçimi
            DropdownButtonFormField<String>(
              value: movementType,
              items: const [
                DropdownMenuItem(value: "in", child: Text("Stok Giriş")),
                DropdownMenuItem(value: "out", child: Text("Stok Çıkış")),
              ],
              onChanged: (v) => setState(() => movementType = v!),
              decoration: const InputDecoration(labelText: "Hareket Türü"),
            ),

            const SizedBox(height: 8),
            supplierDropdown,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupplierFormPage()),
                  );
                  if (ok == true) {
                    await fetchSuppliers();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Tedarikçi Ekle"),
              ),
            ),

            TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: "Miktar"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceCtrl,
              decoration: InputDecoration(
                labelText: movementType == "out"
                    ? "Satış Fiyatı ($currency)"
                    : "Alış Fiyatı ($currency)",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: "Not"),
            ),

            const SizedBox(height: 16),
            if (categoryVariants.isNotEmpty) ...[
              Text(
                "Varyantlar",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              if (categoryVariants.contains("Renk")) ...[
                const SizedBox(height: 10),
                const Text("Renk Seçin"),
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
              ],

              if (categoryVariants.contains("Marka Adı")) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _brandNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Marka Adı (serbest)",
                  ),
                ),
              ],

              if (categoryVariants.contains("Ekran Teknolojisi")) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedEkranTeknolojisi,
                  items: ekranTeknolojileri
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedEkranTeknolojisi = v),
                  decoration: const InputDecoration(
                    labelText: "Ekran Teknolojisi",
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveMovement,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
