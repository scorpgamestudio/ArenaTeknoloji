import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class SupplierFormPage extends StatefulWidget {
  final Map<String, dynamic>? supplier; // düzenleme için mevcut tedarikçi

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _taxNo = TextEditingController();
  final _address = TextEditingController();
  final _seal = TextEditingController(); // Mühür / Logo ismi
  final _brands = TextEditingController(); // Genel sattığı markalar

  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _name.text = s["name"] ?? "";
      _phone.text = s["phone"] ?? "";
      _email.text = s["email"] ?? "";
      _taxNo.text = s["tax_no"] ?? "";
      _address.text = s["address"] ?? "";
      _seal.text = s["seal_text"] ?? "";
      _brands.text = (s["brands"] as List?)?.join(", ") ?? "";
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final body = {
      "name": _name.text,
      "phone": _phone.text.isEmpty ? null : _phone.text,
      "email": _email.text.isEmpty ? null : _email.text,
      "tax_no": _taxNo.text.isEmpty ? null : _taxNo.text,
      "address": _address.text.isEmpty ? null : _address.text,
      "seal_text": _seal.text.isEmpty ? null : _seal.text,
      "brands": _brands.text.isEmpty
          ? []
          : _brands.text.split(",").map((e) => e.trim()).toList(),
    };

    http.Response res;
    if (widget.supplier == null) {
      // yeni ekleme
      res = await http.post(
        Uri.parse("$API_BASE/suppliers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
    } else {
      // düzenleme
      final id = widget.supplier!["id"];
      res = await http.put(
        Uri.parse("$API_BASE/suppliers/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
    }

    setState(() => loading = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (context.mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${res.statusCode} - ${res.body}")),
      );
    }
  }

  Future<void> deleteSupplier() async {
    if (widget.supplier == null) return;
    final id = widget.supplier!["id"];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tedarikçiyi Sil"),
        content: const Text("Bu tedarikçiyi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await http.delete(Uri.parse("$API_BASE/suppliers/$id"));
    if (res.statusCode == 200) {
      if (context.mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız: ${res.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Tedarikçi Düzenle" : "Tedarikçi Ekle"),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: deleteSupplier,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Ad / Ünvan"),
                validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Telefon"),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "E-posta"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _taxNo,
                decoration: const InputDecoration(labelText: "Vergi No"),
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Adres"),
                maxLines: 3,
              ),
              TextFormField(
                controller: _seal,
                decoration: const InputDecoration(
                  labelText: "Mühür Yazısı / Logo İsmi (opsiyonel)",
                ),
              ),
              TextFormField(
                controller: _brands,
                decoration: const InputDecoration(
                  labelText: "Genel Olarak Sattığı Markalar (virgülle ayır)",
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : save,
                child: loading
                    ? const CircularProgressIndicator()
                    : Text(isEdit ? "Güncelle" : "Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
