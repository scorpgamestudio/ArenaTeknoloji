import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart'; // API_BASE için

// 🔹 Sabit varyant seçenekleri
// Varyant seçenekleri ve açıklamaları
const variantOptions = {
  "Renk": "Ürün renk seçeneği (siyah, beyaz, mavi vb.)",
  "Kasalı": "Ürün kasa ile birlikte gelir mi?",
  "Çıtalı": "Ekran çerçeveli mi?",
  "Ekran Teknolojisi": "TFT, INCELL, OLED gibi ekran tipleri",
  "Marka Adı": "Ürünün tedarik markası, boş ise OEM yazılır",
  "Batarya Tipi": "Standart veya Güçlendirilmiş",
  "Kapak Türü": "Kamera camlı veya düz kapak",
  "Durumu": "Sıfır Orjinal, Çıkma Orjinal vb.",
};

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

  // 🔹 Kategori ekle (Varyant seçimi ile birlikte)
  Future<void> addCategory() async {
    final nameController = TextEditingController();
    int? parentId;
    final selectedVariants = <String>{};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Kategori Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Kategori Adı",
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: "Üst Kategori",
                      ),
                      value: null,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Yok"),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem<int?>(
                            value: int.tryParse(c["id"].toString()),
                            child: Text(c["name"]),
                          ),
                        ),
                      ],
                      onChanged: (val) => parentId = val,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Varyant Seçenekleri",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: variantOptions.entries.map((entry) {
                        final opt = entry.key;
                        final desc = entry.value;
                        final checked = selectedVariants.contains(opt);
                        return FilterChip(
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                opt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          selected: checked,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (val) {
                                selectedVariants.add(opt);
                              } else {
                                selectedVariants.remove(opt);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      "name": nameController.text.trim(),
                      "parent_id": parentId,
                      "variant_options": selectedVariants.toList(),
                    });
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
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
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
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
                    .map(
                      (b) => DropdownMenuItem<int?>(
                        value: int.tryParse(b["id"].toString()),
                        child: Text(b["name"]),
                      ),
                    )
                    .toList(),
                onChanged: (val) => brandId = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "name": nameController.text.trim(),
                  "brand_id": brandId,
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
          "Bu $type kaydına bağlı alt kayıtlar olabilir.\n"
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

    if (confirm != true) return;

    try {
      final url = Uri.parse("$API_BASE/$type/$id");
      final res = await http.delete(url);

      if (!mounted) return;
      if (res.statusCode == 200) {
        await fetchAll();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name silindi")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silinemedi (${res.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
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

                    // 🔹 Backend'den variant_options gelecek
                    List<dynamic> variantOptions = [];
                    if (c["variant_options"] != null) {
                      try {
                        variantOptions = c["variant_options"] is String
                            ? jsonDecode(c["variant_options"])
                            : (c["variant_options"] as List);
                      } catch (e) {
                        debugPrint("Varyant decode hatası: $e");
                      }
                    }

                    return ListTile(
                      title: Text(c["name"] ?? ""),
                      subtitle: variantOptions.isNotEmpty
                          ? Text("Varyantlar: ${variantOptions.join(', ')}")
                          : const Text("Varyant yok"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editCategory(c), // ✅ düzenleme
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              final id = int.tryParse(c["id"].toString());
                              if (id != null) {
                                deleteItem("categories", id, c["name"]);
                              }
                            },
                          ),
                        ],
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

  Future<void> editCategory(Map c) async {
    final nameController = TextEditingController(text: c["name"]);
    Set<String> selectedVariants = {};

    if (c["variant_options"] != null) {
      selectedVariants = Set<String>.from(c["variant_options"]);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Kategori Düzenle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Kategori Adı",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: variantOptions.entries.map((entry) {
                      final opt = entry.key;
                      final desc = entry.value;
                      final checked = selectedVariants.contains(opt);
                      return FilterChip(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              opt,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        selected: checked,
                        onSelected: (val) {
                          setStateDialog(() {
                            if (val) {
                              selectedVariants.add(opt);
                            } else {
                              selectedVariants.remove(opt);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      "name": nameController.text.trim(),
                      "variant_options": selectedVariants
                          .toList(), // ✅ doğru key
                    });
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result["name"].isNotEmpty) {
      final id = c["id"];
      await http.put(
        Uri.parse("$API_BASE/categories/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(result),
      );
      fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanımlar"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color.fromARGB(255, 239, 255, 231),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: "Kategoriler"),
                Tab(text: "Markalar"),
                Tab(text: "Modeller"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildCategoryList(), buildBrandList(), buildModelList()],
      ),
    );
  }
}
