import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cari_form_page.dart';

// 🔹 API adresi
const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

class CariPage extends StatefulWidget {
  const CariPage({super.key});

  @override
  State<CariPage> createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  List<Map<String, dynamic>> cariler = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCariler();
  }

  // 🔹 Cari listesi çek
  Future<void> _fetchCariler() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$API_BASE/cariler"));
      if (res.statusCode == 200) {
        final List data = jsonDecode(
          utf8.decode(res.bodyBytes),
        ); // ✅ Türkçe fix
        setState(() {
          cariler = List<Map<String, dynamic>>.from(data);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Cari listesi alınamadı: $e");
      setState(() => loading = false);
    }
  }

  // 🔹 Yeni cari ekle
  void _addCari() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CariFormPage()),
    );

    if (result == true) {
      _fetchCariler(); // yeni kayıttan sonra listeyi yenile
    }
  }

  // 🔹 Cari düzenle
  void _editCari(Map<String, dynamic> cari) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CariFormPage(initialData: cari)),
    );

    if (result == true) {
      _fetchCariler(); // düzenlemeden sonra listeyi yenile
    }
  }

  // 🔹 Cari sil
  Future<void> _deleteCari(int id) async {
    try {
      final res = await http.delete(Uri.parse("$API_BASE/cariler/$id"));
      debugPrint("DELETE status: ${res.statusCode}, body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data is Map && data["success"] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Cari silindi ✅")));
          _fetchCariler();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Silinemedi: ${res.body}")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: ${res.statusCode}")));
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cari Hesaplar")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cariler.isEmpty
          ? const Center(child: Text("Henüz cari eklenmedi"))
          : ListView.builder(
              itemCount: cariler.length,
              itemBuilder: (ctx, i) {
                final c = cariler[i];
                final id = int.tryParse(c["id"].toString());

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c["ad_soyad"] ?? ""),
                    subtitle: Text(c["firma_adi"] ?? ""),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c["telefon"] ?? ""),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: id == null ? null : () => _deleteCari(id),
                        ),
                      ],
                    ),
                    onTap: () => _editCari(c),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCari,
        icon: const Icon(Icons.add),
        label: const Text("Cari Oluştur"),
      ),
    );
  }
}
