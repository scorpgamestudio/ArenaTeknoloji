import 'dart:convert';
import 'package:arena_teknoloji/definitions_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// İçerik sayfaları
import 'package:arena_teknoloji/product_detail.dart';
import 'package:arena_teknoloji/product_form.dart';
import 'package:arena_teknoloji/supplier_list.dart';
import 'package:arena_teknoloji/critical_list.dart';

// 🔹 API adresi
const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

// 🔹 Global currency
String globalCurrency = "TRY";

// 🔹 Ayarları yükle
Future<void> loadSettings() async {
  try {
    final res = await http.get(Uri.parse("$API_BASE/settings"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      globalCurrency = data["currency"] ?? "TRY";
    }
  } catch (e) {
    debugPrint("Ayarlar alınamadı: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSettings(); // önce ayarları çek
  runApp(const ArenaApp());
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena Teknoloji',

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: 6,
          shadowColor: Colors.black54,
          backgroundColor: Color.fromARGB(255, 176, 255, 230),
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// Sol menü sabit, sağ taraf içerik
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();

  void _go(String route) {
    _contentNavKey.currentState!.pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ==== Sol Menü ====
          SizedBox(
            width: 230,
            child: Material(
              elevation: 12,
              shadowColor: Colors.black54,
              child: Container(
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Center(child: ShineLogo()),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: const Text("Ürünler"),
                      onTap: () => _go('/products'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text("Tedarikçiler"),
                      onTap: () => _go('/suppliers'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: const Text("Kritik Stok"),
                      onTap: () => _go('/critical'),
                    ),
                    ListTile(
  leading: const Icon(Icons.category),
  title: const Text("Tanımlar"),
  onTap: () => _go('/definitions'),
),

                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text("Raporlama"),
                      onTap: () => _go('/reports'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Ayarlar"),
                      onTap: () => _go('/settings'),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "© Arena Teknoloji",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==== Sağ içerik ====
          Expanded(
            child: Navigator(
              key: _contentNavKey,
              initialRoute: '/products',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/products':
                    return MaterialPageRoute(
                      builder: (_) => const ProductsPage(),
                    );
                  case '/suppliers':
                    return MaterialPageRoute(
                      builder: (_) => const SupplierListPage(),
                    );
                  case '/critical':
                    return MaterialPageRoute(
                      builder: (_) => const CriticalListPage(),
                    );
                    case '/definitions':
  return MaterialPageRoute(
    builder: (_) => const DefinitionsPage(),
  );

                  case '/reports':
                    return MaterialPageRoute(
                      builder: (_) => const ReportsPage(),
                    );
                  case '/settings':
                    return MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    );
                  // Detay ve form rotaları
                  case '/productForm':
                    return MaterialPageRoute(
                      builder: (_) => const ProductFormPage(),
                    );
                  case '/productDetail':
                    final Map product = settings.arguments as Map;
                    return MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: product),
                    );
                  default:
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text("Sayfa bulunamadı")),
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ürünler Sayfası
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  List filteredProducts = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _searchCtrl.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$API_BASE/products"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        products = data;
        filteredProducts = data;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void _filterProducts() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) {
        final name = (p["name"] ?? "").toString().toLowerCase();
        final barcode = (p["barcode"] ?? "").toString().toLowerCase();
        return name.contains(query) || barcode.contains(query);
      }).toList();
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Ürünler"),
      automaticallyImplyLeading: false,
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 🔹 Arama kutusu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Ürün ara (isim veya barkod)...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // 🔹 Tablo görünümü (şık ve sola dayalı)
              Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: Container(
      width: double.infinity, // ekran boyunca yayılsın
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: DataTableTheme(
        data: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            Colors.blue.shade50,
          ),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          dividerThickness: 1,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth;
            return DataTable(
              columnSpacing: tableWidth / 12, // genişliğe göre boşluk ayarı
              showBottomBorder: true,
             columns: const [
  DataColumn(label: Text("Ürün Adı", textAlign: TextAlign.left)),
  DataColumn(label: Text("Stok", textAlign: TextAlign.left)),
  DataColumn(label: Text("Durum", textAlign: TextAlign.left)),
  DataColumn(label: Text("Satış Fiyatı", textAlign: TextAlign.left)),
  DataColumn(label: Text("Maliyet", textAlign: TextAlign.left)),
],


             rows: filteredProducts.map((p) {
  final stock = double.tryParse(p["stock_on_hand"].toString()) ?? 0;

  return DataRow(
    cells: [
      // Ürün Adı
      DataCell(
        Tooltip(
          message: (p["compatibles"] ?? []).isEmpty
              ? "Uyumlu model yok"
              : (p["compatibles"] as List).map((c) => c["name"]).join(", "),
          child: Text(p["name"] ?? ""),
        ),
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(
            '/productDetail',
            arguments: p,
          );
          if (result == true) fetchProducts();
        },
      ),

      // Stok (sadece sayı, ortalı)
      DataCell(
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      numFmt.format(stock),
      textAlign: TextAlign.left,
    ),
  ),
),


      // Durum (etiket ayrı sütun)
      DataCell(
  Align(
    alignment: Alignment.centerLeft,
    child: stock > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "Stokta Var",
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "Stokta Yok",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
  ),
),


      // Satış Fiyatı
      DataCell(
        Text(
          "${numFmt.format(double.tryParse(p["sale_price"].toString()) ?? 0)} $globalCurrency",
        ),
      ),

      // Maliyet
      DataCell(
        Text(
          "${numFmt.format(double.tryParse(p["avg_cost"].toString()) ?? 0)} $globalCurrency",
        ),
      ),
    ],
  );
}).toList(),

            );
          },
        ),
      ),
    ),
  ),
),

            ],
          ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () async {
        final result = await Navigator.of(context).pushNamed('/productForm');
        if (result == true) fetchProducts();
      },
    ),
  );
}

}

/// Raporlama Sayfası
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  double totalValue = 0;
  String currency = globalCurrency;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    final res = await http.get(Uri.parse("$API_BASE/report/stock_value"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        totalValue = (data["total_value"] ?? 0).toDouble();
        currency = data["currency"] ?? globalCurrency;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raporlama")),
      body: Center(
        child: Text(
          "Toplam Sermaye: ${numFmt.format(totalValue)} $currency",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

/// Ayarlar Sayfası
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedCurrency = globalCurrency;
  final currencies = ["TRY", "USD", "EUR"];

  Future<void> saveSettings() async {
    final body = {"currency": selectedCurrency};
    final res = await http.post(
      Uri.parse("$API_BASE/settings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      globalCurrency = selectedCurrency;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Ayarlar kaydedildi")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: const InputDecoration(labelText: "Para Birimi"),
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCurrency = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveSettings,
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logoya shine + shadow efekti
class ShineLogo extends StatefulWidget {
  const ShineLogo({super.key});
  @override
  State<ShineLogo> createState() => _ShineLogoState();
}

class _ShineLogoState extends State<ShineLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: 210,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PhysicalModel(
              color: const Color.fromARGB(48, 2, 154, 255),
              elevation: 35,
              shadowColor: const Color.fromARGB(115, 201, 241, 255),
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/images/logo.png",
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                return Transform.translate(
                  offset: Offset((t * 200) - 100, 0),
                  child: Container(
                    height: 72,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
