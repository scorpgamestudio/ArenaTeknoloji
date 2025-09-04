import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supplier_form.dart';

const String API_BASE = "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

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

  Future<void> fetchSuppliers() async {
    setState(() => loading = true);
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupplierFormPage()),
          );
          if (ok == true) {
            fetchSuppliers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
