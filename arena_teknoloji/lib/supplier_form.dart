import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String API_BASE = "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class SupplierFormPage extends StatefulWidget {
  const SupplierFormPage({super.key});

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

  bool loading = false;

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final body = {
      "name": _name.text,
      "phone": _phone.text.isEmpty ? null : _phone.text,
      "email": _email.text.isEmpty ? null : _email.text,
      "tax_no": _taxNo.text.isEmpty ? null : _taxNo.text,
      "address": _address.text.isEmpty ? null : _address.text,
    };

    final res = await http.post(
      Uri.parse("$API_BASE/suppliers"),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Tedarikçi Ekle")),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : save,
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
