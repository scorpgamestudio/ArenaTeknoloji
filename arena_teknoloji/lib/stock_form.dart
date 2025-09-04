import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supplier_form.dart';

const String API_BASE = "http://businessmanager.arenateknoloji.com";

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

  String movementType = "in"; // varsayılan giriş
  bool loading = false;

  // Suppliers
  List suppliers = [];
  int? selectedSupplierId;
  bool loadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
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

  Future<void> saveMovement() async {
    if (_qtyCtrl.text.isEmpty) return;

    setState(() => loading = true);

    final body = {
      "product_id": widget.product["id"],
      "qty": double.tryParse(_qtyCtrl.text) ?? 0,
      "type": movementType,
      "unit_price": double.tryParse(_priceCtrl.text) ?? 0,
      "ref": "APP",
      "note": _noteCtrl.text,
      "supplier_id": selectedSupplierId,
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
            decoration: const InputDecoration(labelText: "Tedarikçi"),
          );

    return Scaffold(
      appBar: AppBar(title: Text("Stok Hareketi: ${widget.product["name"]}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: movementType,
              items: const [
                DropdownMenuItem(value: "in", child: Text("Stok Giriş")),
                DropdownMenuItem(value: "out", child: Text("Stok Çıkış")),
                DropdownMenuItem(value: "adjust", child: Text("Düzeltme")),
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
                    // yeni eklenen tedarikçiyi otomatik seçmek istersen:
                    // setState(() => selectedSupplierId = int.tryParse(suppliers.first["id"].toString()));
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
              decoration: const InputDecoration(
                labelText: "Alış Fiyatı (birim)",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: "Not"),
            ),
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
