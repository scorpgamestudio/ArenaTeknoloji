import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  // 🔹 Fake data (backend bağlanınca API’den gelecek)
  final List<Map<String, dynamic>> allSales = [
    {
      "id": 1,
      "customer": "Ahmet Yılmaz",
      "company": "Yılmazlar LTD",
      "dateTime": "2025-09-14 10:15",
      "productName": "iPhone 12 Ekran",
      "qty": 1,
      "price": 5000,
      "total": 5000,
    },
    {
      "id": 2,
      "customer": "Ahmet Yılmaz",
      "company": "Yılmazlar LTD",
      "dateTime": "2025-09-14 12:40",
      "productName": "Şarj Kablosu",
      "qty": 3,
      "price": 100,
      "total": 300,
    },
    {
      "id": 3,
      "customer": "Ahmet Yılmaz",
      "company": "Yılmazlar LTD",
      "dateTime": "2025-09-13 14:00",
      "productName": "Kulaklık",
      "qty": 2,
      "price": 400,
      "total": 800,
    },
    {
      "id": 4,
      "customer": "Mehmet Demir",
      "company": "Demir Elektronik",
      "dateTime": "2025-09-13 11:20",
      "productName": "Laptop Batarya",
      "qty": 1,
      "price": 2500,
      "total": 2500,
    },
  ];

  DateTime? _filterStart;
  DateTime? _filterEnd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    // 🔹 Arama filtresi
    String query = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> filtered = allSales.where((s) {
      return s["customer"].toLowerCase().contains(query) ||
          s["company"].toLowerCase().contains(query);
    }).toList();

    // 🔹 Tarih filtresi (sadece Tüm Satışlar’da kullanılıyor)
    if (_filterStart != null && _filterEnd != null) {
      filtered = filtered.where((s) {
        final d = DateFormat("yyyy-MM-dd HH:mm").parse(s["dateTime"]);
        return d.isAfter(_filterStart!.subtract(const Duration(days: 1))) &&
            d.isBefore(_filterEnd!.add(const Duration(days: 1)));
      }).toList();
    }

    // 🔹 Gruplama
    Map<String, List<Map<String, dynamic>>> todaySales = {};
    Map<String, List<Map<String, dynamic>>> yesterdaySales = {};
    Map<String, List<Map<String, dynamic>>> olderSales = {};

    for (var s in filtered) {
      String dateOnly = s["dateTime"].substring(0, 10);
      String key = "${s["customer"]}-${s["company"]}";

      if (dateOnly == todayStr) {
        todaySales.putIfAbsent(key, () => []).add(s);
      } else if (dateOnly == yesterdayStr) {
        yesterdaySales.putIfAbsent(key, () => []).add(s);
      } else {
        olderSales.putIfAbsent(key, () => []).add(s);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Satışlar / Siparişler"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔎 Arama kutusu
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Cari adı veya firma ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildSection("Bugünkü Satışlar", todaySales),
                _buildSection("Dünkü Satışlar", yesterdaySales),
                _buildSection("Tüm Satışlar", olderSales, showFilter: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Yeni satış ekleme sayfası açılacak
        },
        icon: const Icon(Icons.add),
        label: const Text("Yeni Satış"),
      ),
    );
  }

  Widget _buildSection(
    String title,
    Map<String, List<Map<String, dynamic>>> groupedSales, {
    bool showFilter = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (showFilter)
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: _pickDateRange,
              ),
          ],
        ),
        children: groupedSales.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Kayıt yok"),
                ),
              ]
            : groupedSales.entries
                  .map((e) => _buildGroupedCard(e.key, e.value))
                  .toList(),
      ),
    );
  }

  Widget _buildGroupedCard(String key, List<Map<String, dynamic>> sales) {
    final first = sales.first;
    double total = sales.fold<double>(
      0,
      (sum, s) => sum + double.parse(s["total"].toString()),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.people_alt, color: Colors.blue),
        title: Text(
          first["customer"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(first["company"]),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${sales.length} satış", style: const TextStyle(fontSize: 12)),
            Text(
              "${total.toStringAsFixed(2)} ₺",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        onTap: () =>
            _showSalesDetail(first["customer"], first["company"], sales),
      ),
    );
  }

  void _showSalesDetail(
    String customer,
    String company,
    List<Map<String, dynamic>> sales,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "$customer - $company",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: sales.length,
                itemBuilder: (_, i) {
                  final s = sales[i];
                  return ListTile(
                    leading: const Icon(Icons.receipt, color: Colors.blue),
                    title: Text(
                      DateFormat("dd.MM.yyyy HH:mm").format(
                        DateFormat("yyyy-MM-dd HH:mm").parse(s["dateTime"]),
                      ),
                    ),
                    subtitle: Text(
                      "${s["productName"]} x${s["qty"]} @${s["price"]} ₺",
                    ),
                    trailing: Text(
                      "${double.parse(s["total"].toString())} ₺",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Genel Toplam:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "${sales.fold<double>(0, (sum, s) => sum + double.parse(s["total"].toString()))} ₺",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filterStart != null && _filterEnd != null
          ? DateTimeRange(start: _filterStart!, end: _filterEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
    );
    if (picked != null) {
      setState(() {
        _filterStart = picked.start;
        _filterEnd = picked.end;
      });
    }
  }
}
