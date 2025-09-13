import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class CariFormPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const CariFormPage({super.key, this.initialData});

  @override
  State<CariFormPage> createState() => _CariFormPageState();
}

class _CariFormPageState extends State<CariFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _adSoyadCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _cepTelCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  final _ilCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();
  final _postaKoduCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _faturaFirmaCtrl = TextEditingController();
  final _faturaAdresCtrl = TextEditingController();
  final _faturaIlCtrl = TextEditingController();
  final _faturaIlceCtrl = TextEditingController();
  final _faturaPostaKoduCtrl = TextEditingController();
  final _vergiDairesiCtrl = TextEditingController();
  final _vergiNoCtrl = TextEditingController();

  bool _sameAsContact = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _adSoyadCtrl.text = d["ad_soyad"] ?? "";
      _firmaCtrl.text = d["firma_adi"] ?? "";
      _telCtrl.text = d["telefon"] ?? "";
      _cepTelCtrl.text = d["cep_telefon"] ?? "";
      _emailCtrl.text = d["email"] ?? "";
      _webCtrl.text = d["web_site"] ?? "";
      _adresCtrl.text = d["adres"] ?? "";
      _ilCtrl.text = d["il"] ?? "";
      _ilceCtrl.text = d["ilce"] ?? "";
      _postaKoduCtrl.text = d["posta_kodu"] ?? "";

      _faturaFirmaCtrl.text = d["fatura_firma_adi"] ?? "";
      _faturaAdresCtrl.text = d["fatura_adres"] ?? "";
      _faturaIlCtrl.text = d["fatura_il"] ?? "";
      _faturaIlceCtrl.text = d["fatura_ilce"] ?? "";
      _faturaPostaKoduCtrl.text = d["fatura_posta_kodu"] ?? "";
      _vergiDairesiCtrl.text = d["vergi_dairesi"] ?? "";
      _vergiNoCtrl.text = d["vergi_no"] ?? "";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final body = {
      "adSoyad": _adSoyadCtrl.text,
      "firmaAdi": _firmaCtrl.text,
      "telefon": _telCtrl.text,
      "cepTelefon": _cepTelCtrl.text,
      "email": _emailCtrl.text,
      "webSite": _webCtrl.text,
      "adres": _adresCtrl.text,
      "il": _ilCtrl.text,
      "ilce": _ilceCtrl.text,
      "postaKodu": _postaKoduCtrl.text,
      "faturaFirmaAdi": _faturaFirmaCtrl.text,
      "faturaAdres": _faturaAdresCtrl.text,
      "faturaIl": _faturaIlCtrl.text,
      "faturaIlce": _faturaIlceCtrl.text,
      "faturaPostaKodu": _faturaPostaKoduCtrl.text,
      "vergiDairesi": _vergiDairesiCtrl.text,
      "vergiNo": _vergiNoCtrl.text,
    };

    try {
      final url = widget.initialData == null
          ? Uri.parse("$API_BASE/cariler")
          : Uri.parse("$API_BASE/cariler/${widget.initialData!["id"]}");

      final res = await (widget.initialData == null
          ? http.post(
              url,
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: jsonEncode(body),
            )
          : http.put(
              url,
              headers: {"Content-Type": "application/json; charset=utf-8"},
              body: jsonEncode(body),
            ));

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${res.statusCode} - ${res.body}")),
        );
      }
    } catch (e) {
      debugPrint("Cari kaydetme hatası: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _toggleSameAsContact(bool? val) {
    setState(() {
      _sameAsContact = val ?? false;
      if (_sameAsContact) {
        _faturaAdresCtrl.text = _adresCtrl.text;
        _faturaIlCtrl.text = _ilCtrl.text;
        _faturaIlceCtrl.text = _ilceCtrl.text;
        _faturaPostaKoduCtrl.text = _postaKoduCtrl.text;
      } else {
        _faturaAdresCtrl.clear();
        _faturaIlCtrl.clear();
        _faturaIlceCtrl.clear();
        _faturaPostaKoduCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null ? "Yeni Cari Ekle" : "Cari Düzenle",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "İletişim Bilgileri",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _adSoyadCtrl,
                decoration: const InputDecoration(labelText: "Ad Soyad"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ad soyad gerekli" : null,
              ),
              TextFormField(
                controller: _firmaCtrl,
                decoration: const InputDecoration(labelText: "Firma Adı"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Firma adı gerekli" : null,
              ),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: "Telefon"),
              ),
              TextFormField(
                controller: _cepTelCtrl,
                decoration: const InputDecoration(labelText: "Cep Telefonu"),
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "E-posta"),
              ),
              TextFormField(
                controller: _webCtrl,
                decoration: const InputDecoration(labelText: "Web Sitesi"),
              ),
              TextFormField(
                controller: _adresCtrl,
                decoration: const InputDecoration(labelText: "Adres"),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ilCtrl,
                      decoration: const InputDecoration(labelText: "İl"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _ilceCtrl,
                      decoration: const InputDecoration(labelText: "İlçe"),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _postaKoduCtrl,
                decoration: const InputDecoration(labelText: "Posta Kodu"),
              ),
              const Divider(thickness: 2),
              const Text(
                "Fatura Bilgileri",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                value: _sameAsContact,
                onChanged: _toggleSameAsContact,
                title: const Text("Fatura adresi iletişim adresiyle aynı"),
              ),
              TextFormField(
                controller: _faturaFirmaCtrl,
                decoration: const InputDecoration(
                  labelText: "Fatura Firma Adı",
                ),
              ),
              TextFormField(
                controller: _faturaAdresCtrl,
                decoration: const InputDecoration(labelText: "Fatura Adresi"),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _faturaIlCtrl,
                      decoration: const InputDecoration(labelText: "Fatura İl"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _faturaIlceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Fatura İlçe",
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _faturaPostaKoduCtrl,
                decoration: const InputDecoration(
                  labelText: "Fatura Posta Kodu",
                ),
              ),
              TextFormField(
                controller: _vergiDairesiCtrl,
                decoration: const InputDecoration(labelText: "Vergi Dairesi"),
              ),
              TextFormField(
                controller: _vergiNoCtrl,
                decoration: const InputDecoration(labelText: "Vergi No / T.C."),
              ),
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
