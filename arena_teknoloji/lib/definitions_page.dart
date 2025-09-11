import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart'; // API_BASE için

class DefinitionsPage extends StatefulWidget {
  const DefinitionsPage({super.key});

  @override
  State<DefinitionsPage> createState() => _DefinitionsPageState();
}

class _DefinitionsPageState extends State<DefinitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List categories = [];
  List brands = [];
  List models = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    try {
      final catRes = await http.get(Uri.parse("$API_BASE/categories"));
      final brandRes = await http.get(Uri.parse("$API_BASE/brands"));
      final modelRes = await http.get(Uri.parse("$API_BASE/models"));

      if (catRes.statusCode == 200) categories = jsonDecode(catRes.body);
      if (brandRes.statusCode == 200) brands = jsonDecode(brandRes.body);
      if (modelRes.statusCode == 200) models = jsonDecode(modelRes.body);
    } catch (e) {
      debugPrint("Tanımlar alınamadı: $e");
    }
    setState(() => loading = false);
  }

  // 🔹 Kategori ekle
  Future<void> addCategory() async {
    final nameController = TextEditingController();
    int? parentId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Kategori Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Kategori Adı"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
  decoration: const InputDecoration(labelText: "Üst Kategori"),
  value: null,
  items: [
    const DropdownMenuItem<int?>(value: null, child: Text("Yok")),
    ...categories.map((c) => DropdownMenuItem<int?>(
          value: int.tryParse(c["id"].toString()), // ✅ String → int
          child: Text(c["name"]),
        )),
  ],
  onChanged: (val) => parentId = val,
),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ✅ sadece kapatır
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "name": nameController.text.trim(),
                  "parent_id": parentId
                });
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );

    if (result != null && result["name"].isNotEmpty) {
      await http.post(
        Uri.parse("$API_BASE/categories"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(result),
      );
      fetchAll();
    }
  }

  // 🔹 Marka ekle
  Future<void> addBrand() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Marka Ekle"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Marka Adı"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ✅ kapatır
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await http.post(
        Uri.parse("$API_BASE/brands"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": result}),
      );
      fetchAll();
    }
  }

  // 🔹 Model ekle
  Future<void> addModel() async {
    final nameController = TextEditingController();
    int? brandId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Model Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Model Adı"),
              ),
              const SizedBox(height: 12),
             DropdownButtonFormField<int?>(
  decoration: const InputDecoration(labelText: "Marka Seç"),
  items: brands
      .map((b) => DropdownMenuItem<int?>(
            value: int.tryParse(b["id"].toString()), // ✅
            child: Text(b["name"]),
          ))
      .toList(),
  onChanged: (val) => brandId = val,
),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ✅ kapatır
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "name": nameController.text.trim(),
                  "brand_id": brandId
                });
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );

    if (result != null &&
        result["name"].isNotEmpty &&
        result["brand_id"] != null) {
      await http.post(
        Uri.parse("$API_BASE/models"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(result),
      );
      fetchAll();
    }
  }

Future<void> deleteItem(String type, dynamic rawId, String name) async {
  final id = int.tryParse(rawId.toString());
  if (id == null) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Silme Onayı"),
      content: Text(
        "“$name” kaydını silmek üzeresiniz.\n\n"
        "Bu $type kaydına bağlı alt kayıtlar (alt kategoriler, ürünler vb.) olabilir.\n"
        "Silmek istediğinize emin misiniz?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Evet, Sil"),
        ),
      ],
    ),
  );

  if (confirm != true) return; // Vazgeçti

  try {
    final url = Uri.parse("$API_BASE/$type/$id");
    final res = await http.delete(url);

    if (!mounted) return;
    if (res.statusCode == 200) {
      await fetchAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$name silindi")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silinemedi (${res.statusCode})")),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Silme hatası: $e")),
    );
  }
}




  Widget buildCategoryList() {
    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final c = categories[i];
                   final parent = categories.firstWhere(
  (p) => p["id"].toString() == (c["parent_id"] ?? '').toString(),
  orElse: () => null,
);

                    return ListTile(
                      title: Text(c["name"]),
                      subtitle: parent != null ? Text("Üst: ${parent["name"]}") : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                     onPressed: () {
  final id = int.tryParse(c["id"].toString());
  if (id != null) deleteItem("categories", id, c["name"]);
},


                      ),
                    );
                  },
                ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Kategori Ekle"),
          onPressed: addCategory,
        ),
      ],
    );
  }

  Widget buildBrandList() {
    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: brands.length,
                  itemBuilder: (context, i) {
                    final b = brands[i];
                    return ListTile(
                      title: Text(b["name"]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                     onPressed: () {
  final id = int.tryParse(b["id"].toString());
  if (id != null) deleteItem("brands", id, b["name"]);
},


                      ),
                    );
                  },
                ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Marka Ekle"),
          onPressed: addBrand,
        ),
      ],
    );
  }

  Widget buildModelList() {
    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, i) {
                    final m = models[i];
                    return ListTile(
                      title: Text(m["name"]),
                      subtitle: Text("Marka: ${m["brand_name"] ?? '-'}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
  final id = int.tryParse(m["id"].toString());
  if (id != null) deleteItem("models", id, m["name"]);
},


                      ),
                    );
                  },
                ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Model Ekle"),
          onPressed: addModel,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanımlar"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Kategoriler"),
            Tab(text: "Markalar"),
            Tab(text: "Modeller"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildCategoryList(),
          buildBrandList(),
          buildModelList(),
        ],
      ),
    );
  }
}
