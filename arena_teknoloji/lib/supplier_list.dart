import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supplier_form.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  List suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
  }

  /// 🔹 Tedarikçileri getir
  Future<void> fetchSuppliers() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$API_BASE/suppliers"));
      if (res.statusCode == 200) {
        setState(() {
          suppliers = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tedarikçi listesi alınamadı: ${res.statusCode}"),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  /// 🔹 Tedarikçi sil
  Future<void> deleteSupplier(dynamic id) async {
    try {
      final res = await http.delete(Uri.parse("$API_BASE/suppliers/$id"));
      debugPrint("DELETE RESPONSE: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          suppliers.removeWhere((x) => x["id"].toString() == id.toString());
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Tedarikçi silindi ✅")));
      } else {
        debugPrint("Silme hatası: ${res.statusCode} - ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme başarısız: ${res.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Silme exception: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tedarikçiler")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
          ? const Center(child: Text("Henüz tedarikçi yok"))
          : ListView.separated(
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = suppliers[i];
                return ListTile(
                  title: Text(s["name"] ?? ""),
                  subtitle: Text(
                    [
                      if (s["phone"] != null) "Tel: ${s["phone"]}",
                      if (s["email"] != null) "Mail: ${s["email"]}",
                      if (s["tax_no"] != null) "VKN: ${s["tax_no"]}",
                    ].join("  •  "),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔹 Düzenle butonu
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final ok = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupplierFormPage(supplier: s),
                            ),
                          );
                          if (ok == true) fetchSuppliers();
                        },
                      ),

                      // 🔹 Sil butonu
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Emin misiniz?"),
                              content: Text(
                                "${s["name"]} adlı tedarikçiyi silmek istediğinize emin misiniz?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text("İptal"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteSupplier(s["id"]);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupplierFormPage()),
          );
          if (ok == true) fetchSuppliers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
