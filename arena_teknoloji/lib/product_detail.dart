import 'dart:convert';
import 'package:arena_teknoloji/stock_form.dart';
import 'package:arena_teknoloji/stock_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String API_BASE = "http://businessmanager.arenateknoloji.com";

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
  final numFmt = NumberFormat("#,##0.##", "tr_TR");
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl = TextEditingController(text: p["sku"]);
    _nameCtrl = TextEditingController(text: p["name"]);
    _barcodeCtrl = TextEditingController(text: p["barcode"] ?? "");
    _purchaseCtrl = TextEditingController(
      text: numFmt.format(double.tryParse(p["purchase_price"].toString()) ?? 0),
    );
    _saleCtrl = TextEditingController(
      text: numFmt.format(double.tryParse(p["sale_price"].toString()) ?? 0),
    );
    _criticalCtrl = TextEditingController(
      text: numFmt.format(double.tryParse(p["critical_stock"].toString()) ?? 0),
    );
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
    };

    final res = await http.put(
      Uri.parse("$API_BASE/products/${widget.product["id"]}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
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
      appBar: AppBar(title: Text("Ürün Düzenle")),
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
              decoration: const InputDecoration(labelText: "Alış Fiyatı"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _saleCtrl,
              decoration: const InputDecoration(labelText: "Satış Fiyatı"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _criticalCtrl,
              decoration: const InputDecoration(labelText: "Kritik Stok"),
              keyboardType: TextInputType.number,
            ),
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
                if (result == true) {
                  if (context.mounted)
                    Navigator.pop(context, true); // listeyi yenilesin
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
