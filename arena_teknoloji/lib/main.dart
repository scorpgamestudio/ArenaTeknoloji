import 'dart:convert';
import 'package:arena_teknoloji/reports_page.dart';
import 'package:arena_teknoloji/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Sayfalar
import 'config.dart';
import 'home_page.dart';
import 'products_page.dart';
import 'product_detail.dart';
import 'product_form.dart';
import 'supplier_list.dart';
import 'critical_list.dart';
import 'definitions_page.dart';

const String API_BASE =
    "https://arenateknoloji.com/MagazaOtomasyon/api/index.php";

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
          backgroundColor: Color.fromARGB(255, 225, 255, 176),
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
          const SizedBox(height: 8),

          // 🔹 Logonun altındaki kurumsal yazı
          const Center(
            child: Text(
              "Akıllı Entegre Stok Yönetim\nTedarikçi Yazılımı V2.1",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 0, 42, 255),
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color.fromARGB(66, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
const Divider(thickness: 3, color: Color.fromARGB(133, 136, 0, 255)),

                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text("Ana Sayfa"),
                      onTap: () => _go('/home'),
                    ),
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

                    // ✅ En alta logo ekledik
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Center(
                    child: Image.asset(
                      "assets/images/Splash.png", // senin eklediğin dosya adı
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "© Arena Teknoloji",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 15),
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
              initialRoute: '/home', // ✅ İlk açılış Ana Sayfa
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/home':
                    return MaterialPageRoute(builder: (_) => const HomePage());
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
