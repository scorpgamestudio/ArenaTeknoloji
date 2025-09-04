import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE = "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

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
  final numFmt = NumberFormat("#,##0.##", "tr_TR");
  bool loading = false;

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final body = {
      "sku": _skuCtrl.text,
      "barcode": _barcodeCtrl.text,
      "name": _nameCtrl.text,
      "purchase_price":
          double.tryParse(_purchaseCtrl.text.replaceAll(",", ".")) ?? 0,
      "sale_price": double.tryParse(_saleCtrl.text.replaceAll(",", ".")) ?? 0,
      "critical_stock":
          double.tryParse(_criticalCtrl.text.replaceAll(",", ".")) ?? 0,

      "unit": "adet",
    };

    try {
      final res = await http.post(
        Uri.parse("$API_BASE/products"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      setState(() => loading = false);

      if (res.statusCode == 201) {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } else {
        debugPrint("❌ HATA: ${res.statusCode} - ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata ${res.statusCode}: ${res.body}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("❌ Exception: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("İstek başarısız: $e")));
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
                decoration: const InputDecoration(labelText: "SKU"),
                validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Ürün Adı"),
                validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
              ),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(labelText: "Barkod"),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : saveProduct,
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
