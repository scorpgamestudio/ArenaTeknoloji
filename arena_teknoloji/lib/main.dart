import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// İçerik sayfaları
import 'package:arena_teknoloji/product_detail.dart';
import 'package:arena_teknoloji/product_form.dart';
import 'package:arena_teknoloji/supplier_list.dart';
import 'package:arena_teknoloji/critical_list.dart';

const String API_BASE = "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

void main() {
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
    elevation: 6,                    // belirgin gölge
    shadowColor: Colors.black54,     // gölge rengi
    backgroundColor: Color.fromARGB(255, 176, 255, 230),   // AppBar yüzeyi
    foregroundColor: Colors.black87, // yazı/icon rengi
    surfaceTintColor: Colors.transparent, // M3’ün mat filtresini kapat
  ),
),

      home: const HomeShell(), // <- sabit menülü kabuk
    );
  }
}

/// Sol menüyü sabit tutan kabuk; sağda kendi Navigator'ına sahip.
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
          // ===== Left side menu (fixed) with visible shadow =====
          SizedBox(
            width: 230,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Asıl panel (Material elevation)
                Material(
                  elevation: 12,
                  shadowColor: Colors.black54,
                  child: Container(
                    color: Colors.blue.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const Center(child: ShineLogo()),
                        const SizedBox(height: 8),
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

                // Sağ kenarda belirgin “ayraç” gölgesi (gradient şerit)
                Positioned(
                  right: -1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== Right side content (its own Navigator) =====
          Expanded(
            child: Navigator(
              key: _contentNavKey,
              initialRoute: '/products',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/products':
                    return MaterialPageRoute(builder: (_) => const ProductsPage());
                  case '/suppliers':
                    return MaterialPageRoute(builder: (_) => const SupplierListPage());
                  case '/critical':
                    return MaterialPageRoute(builder: (_) => const CriticalListPage());
                  // Detay ve form rotaları (içeride push ile kullanılır)
                  case '/productForm':
                    return MaterialPageRoute(builder: (_) => const ProductFormPage());
                  case '/productDetail':
                    final Map product = settings.arguments as Map;
                    return MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: product));
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

/// Sağ içerikte görünen Ürünler sayfası
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  bool loading = true;
  final numFmt = NumberFormat("#,##0.##", "tr_TR");

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$API_BASE/products"));
    if (res.statusCode == 200) {
      setState(() {
        products = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // kontrast için beyaz
      appBar: AppBar(title: const Text("Ürünler")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  title: Text(p["name"] ?? ""),
                  subtitle: Text(
                    "Stok: ${numFmt.format(double.tryParse(p["stock_on_hand"].toString()) ?? 0)}"
                    " | Satış: ${numFmt.format(double.tryParse(p["sale_price"].toString()) ?? 0)} ₺"
                    " | Maliyet: ${numFmt.format(double.tryParse(p["avg_cost"].toString()) ?? 0)} ₺",
                  ),
                  onTap: () async {
                    final result = await Navigator.of(context).pushNamed(
                      '/productDetail',
                      arguments: p,
                    );
                    if (result == true) {
                      fetchProducts();
                    }
                  },
                );
              },
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

/// Logoya shine + drop shadow efekti
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
      height: 38, // logonun boyu
      width: 210, // logonun genişliği kadar (uygunsa artır/azalt)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Drop shadow
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

            // Shine çizgisi (taşma olursa ClipRRect kesiyor)
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

