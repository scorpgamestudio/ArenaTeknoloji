import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'supplier_form.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class StockListPage extends StatefulWidget {
  final Map product;
  const StockListPage({super.key, required this.product});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  List movements = [];
  List suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMovements();
    fetchSuppliers();
  }

  Future<void> fetchMovements() async {
    final res = await http.get(
      Uri.parse("$API_BASE/products/${widget.product["id"]}/stock"),
    );
    if (res.statusCode == 200) {
      setState(() {
        movements = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> fetchSuppliers() async {
    final res = await http.get(Uri.parse("$API_BASE/suppliers"));
    if (res.statusCode == 200) {
      setState(() {
        suppliers = jsonDecode(res.body);
      });
    }
  }

  Future<void> updateMovement(Map movement) async {
    // ✅ qty tam sayı olarak ayarlandı
    final qtyCtrl = TextEditingController(
      text: (double.tryParse(movement["qty"].toString()) ?? 0)
          .toInt()
          .toString(),
    );
    final priceCtrl = TextEditingController(
      text: movement["unit_price"].toString(),
    );
    final noteCtrl = TextEditingController(text: movement["note"] ?? "");
    int? selectedSupplierId = int.tryParse(
      movement["supplier_id"]?.toString() ?? "",
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text("Stok Hareketini Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Miktar"),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ], // ❌ ondalık yok
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: "Birim Fiyat"),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                DropdownButtonFormField<int>(
                  value:
                      suppliers.any(
                        (s) =>
                            int.tryParse(s["id"].toString()) ==
                            selectedSupplierId,
                      )
                      ? selectedSupplierId
                      : null, // ✅ listede yoksa null ata
                  items: suppliers
                      .map<DropdownMenuItem<int>>(
                        (s) => DropdownMenuItem<int>(
                          value: int.tryParse(s["id"].toString()),
                          child: Text(s["name"] ?? ""),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedSupplierId = v,
                  decoration: const InputDecoration(labelText: "Tedarikçi"),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupplierFormPage(),
                        ),
                      );
                      if (ok == true) {
                        await fetchSuppliers();
                        Navigator.pop(dialogCtx); // popup kapat
                        updateMovement(movement); // tekrar aç
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Yeni Tedarikçi"),
                  ),
                ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: "Not"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  "qty": int.tryParse(qtyCtrl.text) ?? 0,
                  "unit_price": double.tryParse(priceCtrl.text) ?? 0,
                  "note": noteCtrl.text,
                  "supplier_id": selectedSupplierId,
                };

                final res = await http.put(
                  Uri.parse("$API_BASE/stock/${movement["id"]}"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(body),
                );

                if (res.statusCode == 200) {
                  Navigator.pop(dialogCtx, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: ${res.statusCode}")),
                  );
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      fetchMovements(); // listeyi yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat.decimalPattern("tr_TR"); // 1000 → 1.000

    return Scaffold(
      appBar: AppBar(
        title: Text("Stok Hareketleri: ${widget.product["name"]}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : movements.isEmpty
          ? const Center(child: Text("Henüz hareket yok"))
          : ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final m = movements[index];

                // ✅ qty tam sayı
                final qty = (double.tryParse(m["qty"].toString()) ?? 0).toInt();
                final price = numFmt.format(
                  double.tryParse(m["unit_price"].toString()) ?? 0,
                );
                final currency = m["currency"] ?? "TRY";

                return ListTile(
                  title: Text(
                    "${m["type"] == "in" ? "Giriş" : "Çıkış"} • $qty adet • $price $currency",
                  ),
                  subtitle: Text(
                    "Tedarikçi: ${m["supplier_name"] ?? "-"} • Tarih: ${m["created_at"]}",
                  ),
                  onTap: () => updateMovement(m),
                );
              },
            ),
    );
  }
}
