import 'package:flutter/material.dart';

class SalesFormPage extends StatefulWidget {
  const SalesFormPage({super.key});

  @override
  State<SalesFormPage> createState() => _SalesFormPageState();
}

class _SalesFormPageState extends State<SalesFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Dummy data
  final List<String> customers = List.generate(
    1000,
    (i) => "Müşteri $i - Firma ${i % 50}",
  );
  final List<Map<String, dynamic>> products = List.generate(
    200,
    (i) => {
      "name": "Ürün $i",
      "barcode": "BRC${1000 + i}",
      "price": (50 + i).toDouble(),
    },
  );

  String? selectedCustomer;
  Map<String, dynamic>? selectedProduct;

  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  List<Map<String, dynamic>> cart = [];
  String? paymentType;

  // 🔹 Sepete ürün ekle
  void _addProductToCart() {
    if (selectedProduct == null ||
        qtyCtrl.text.isEmpty ||
        priceCtrl.text.isEmpty)
      return;

    int qty = int.tryParse(qtyCtrl.text) ?? 1;
    double price = double.tryParse(priceCtrl.text) ?? 0;

    setState(() {
      cart.add({
        "product": selectedProduct!["name"],
        "barcode": selectedProduct!["barcode"],
        "qty": qty,
        "price": price,
        "total": qty * price,
      });
      selectedProduct = null;
      qtyCtrl.clear();
      priceCtrl.clear();
    });
  }

  // 🔹 Sepetten sil
  void _removeFromCart(int index) {
    setState(() => cart.removeAt(index));
  }

  double get totalAmount =>
      cart.fold<double>(0, (sum, item) => sum + item["total"]);

  void _saveSale() {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Müşteri seçin")));
      return;
    }
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sepete ürün ekleyin")));
      return;
    }
    if (paymentType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ödeme tipi seçin")));
      return;
    }

    debugPrint("Cari: $selectedCustomer");
    debugPrint("Ürünler: $cart");
    debugPrint("Ödeme: $paymentType");
    debugPrint("Toplam: $totalAmount");

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Satış")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🔎 Müşteri seçimi (arama filtreli)
            ListTile(
              title: Text(selectedCustomer ?? "Müşteri seçin"),
              trailing: const Icon(Icons.search),
              tileColor: Colors.blue.shade50,
              onTap: () async {
                final result = await showSearch<String>(
                  context: context,
                  delegate: CustomerSearchDelegate(customers),
                );
                if (result != null) {
                  setState(() => selectedCustomer = result);
                }
              },
            ),
            const SizedBox(height: 20),

            // 🔎 Ürün seçimi (arama filtreli)
            ListTile(
              title: Text(
                selectedProduct != null
                    ? "${selectedProduct!["name"]} (${selectedProduct!["barcode"]})"
                    : "Ürün seçin",
              ),
              trailing: const Icon(Icons.search),
              tileColor: Colors.orange.shade50,
              onTap: () async {
                final result = await showSearch<Map<String, dynamic>>(
                  context: context,
                  delegate: ProductSearchDelegate(products),
                );
                if (result != null) {
                  setState(() {
                    selectedProduct = result;
                    priceCtrl.text = result["price"]
                        .toString(); // 🔹 fiyat otomatik gelsin
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Adet girme
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Adet",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Fiyat (otomatik gelir ama değiştirilebilir)
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Birim Fiyat (düzenlenebilir)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _addProductToCart,
              icon: const Icon(Icons.add_circle),
              label: const Text("Sepete Ekle"),
            ),

            const SizedBox(height: 20),

            // Sepet listesi
            if (cart.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sepet",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...cart.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text("${item["product"]} x${item["qty"]}"),
                        subtitle: Text("Barkod: ${item["barcode"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${item["total"]} ₺",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFromCart(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Toplam: $totalAmount ₺",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Ödeme tipi
            DropdownButtonFormField<String>(
              value: paymentType,
              items: [
                "Nakit",
                "Kredi Kartı",
                "Havale",
                "Vadeli",
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => paymentType = val),
              decoration: const InputDecoration(
                labelText: "Ödeme Tipi",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _saveSale,
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Cari arama delegesi
class CustomerSearchDelegate extends SearchDelegate<String> {
  final List<String> customers;
  CustomerSearchDelegate(this.customers);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ""),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = customers
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(results[i]),
        onTap: () => close(context, results[i]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

/// 🔹 Ürün arama delegesi
class ProductSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> products;
  ProductSearchDelegate(this.products);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, {}),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where((p) {
      return p["name"].toLowerCase().contains(query.toLowerCase()) ||
          p["barcode"].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(results[i]["name"]),
        subtitle: Text(
          "Barkod: ${results[i]["barcode"]} - ${results[i]["price"]} ₺",
        ),
        onTap: () => close(context, results[i]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
