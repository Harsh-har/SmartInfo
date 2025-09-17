import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await loadConfig();
  runApp(MyApp(config: config));
}

/// ✅ Helper function: safely cast dynamic list into List<Map<String, dynamic>>
List<Map<String, dynamic>> safeList(dynamic data) {
  return (data as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final configString = await rootBundle.loadString('assets/config.json');
    return jsonDecode(configString);
  } catch (e) {
    return {
      "appTitle": "Info App",
      "theme": {"primaryColor": "#1976D2", "accentColor": "#2196F3"},
      "appBar": {"title": "Our Company"},
      "drawer": {"headerTitle": "Company Menu"},
      "gridConfig": {
        "crossAxisCount": 2,
        "spacing": 10,
        "childAspectRatio": 1.0
      },
      "content": {
        "sections": [
          {
            "title": "Products",
            "type": "grid",
            "items": [
              {"title": "Product A", "description": "Best quality product"},
              {"title": "Product B", "description": "High demand in market"},
            ]
          },
          {
            "title": "Services",
            "type": "expandable",
            "items": [
              {
                "title": "Consulting",
                "description": "We provide expert consulting"
              },
              {
                "title": "Support",
                "description": "24/7 customer support available"
              }
            ]
          },
          {
            "title": "About Us",
            "type": "cards",
            "items": [
              {
                "title": "Who We Are",
                "description": "We are a leading company",
                "image": "assets/images/logo.png"
              }
            ]
          },
          {
            "title": "Team",
            "type": "list",
            "items": [
              {"title": "John Doe", "description": "CEO"},
              {"title": "Jane Smith", "description": "CTO"}
            ]
          }
        ]
      }
    };
  }
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config['appTitle'] ?? 'Info App',
      theme: _buildTheme(config),
      home: HomeScreen(config: config),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme(Map<String, dynamic> config) {
    final theme = config['theme'] ?? {};
    final primaryColor = _parseColor(theme['primaryColor']) ?? Colors.blue;
    final accentColor = _parseColor(theme['accentColor']) ?? Colors.blueAccent;

    return ThemeData(
      primarySwatch: _createMaterialColor(primaryColor),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: _createMaterialColor(primaryColor),
        accentColor: accentColor,
      ),
      fontFamily: theme['fontFamily'],
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: _parseColor(theme['appBarTextColor']) ?? Colors.white,
        elevation: (theme['appBarElevation'] ?? 4).toDouble(),
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    final buffer = StringBuffer();
    if (colorString.length == 6 || colorString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(colorString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  MaterialColor _createMaterialColor(Color color) {
    final List strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  const HomeScreen({super.key, required this.config});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Map<String, dynamic>> _sections;

  @override
  void initState() {
    super.initState();
    _sections = safeList(widget.config['content']?['sections']);
  }

  Widget _buildContentScreen(Map<String, dynamic> section) {
    final String type = section['type'] ?? 'grid';
    switch (type) {
      case 'grid':
        return _buildGridView(section);
      case 'list':
        return _buildListView(section);
      case 'cards':
        return _buildCardsView(section);
      case 'expandable':
        return _buildExpandableView(section);
      default:
        return _buildGridView(section);
    }
  }

  Widget _buildGridView(Map<String, dynamic> section) {
    final items = safeList(section['items']);
    final gridConfig = widget.config['gridConfig'] ?? {};
    return GridView.builder(
      padding: EdgeInsets.all((gridConfig['spacing'] ?? 8).toDouble()),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridConfig['crossAxisCount'] ?? 2,
        childAspectRatio: (gridConfig['childAspectRatio'] ?? 1.0).toDouble(),
        crossAxisSpacing: (gridConfig['spacing'] ?? 8).toDouble(),
        mainAxisSpacing: (gridConfig['spacing'] ?? 8).toDouble(),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildCard(items[index]),
    );
  }

  Widget _buildListView(Map<String, dynamic> section) {
    final items = safeList(section['items']);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.label),
          title: Text(items[index]['title'] ?? ''),
          subtitle: Text(items[index]['description'] ?? ''),
        ),
      ),
    );
  }

  Widget _buildCardsView(Map<String, dynamic> section) {
    final items = safeList(section['items']);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: items.map((item) => _buildFeatureCard(item)).toList(),
    );
  }

  Widget _buildExpandableView(Map<String, dynamic> section) {
    final items = safeList(section['items']);
    return ListView(
      children: items.map((item) {
        return ExpansionTile(
          title: Text(item['title'] ?? ''),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(item['description'] ?? ''),
            )
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info, size: 40),
          const SizedBox(height: 8),
          Text(item['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(item['description'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> item) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['image'] != null)
            Image.asset(item['image'],
                height: 150, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                Text(item['description'] ?? ''),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarConfig = widget.config['appBar'] ?? {};
    final drawerConfig = widget.config['drawer'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarConfig['title'] ?? 'Home'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(drawerConfig['headerTitle'] ?? 'Menu',
                  style: const TextStyle(color: Colors.white, fontSize: 24)),
            ),
            for (int i = 0; i < _sections.length; i++)
              ExpansionTile(
                leading: const Icon(Icons.category),
                title: Text(_sections[i]['title'] ?? 'Section ${i + 1}'),
                children: [
                  for (var item in safeList(_sections[i]['items']))
                    ListTile(
                      title: Text(item['title'] ?? ''),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.pop(context);
                      },
                    )
                ],
              ),
          ],
        ),
      ),
      body: _sections.isNotEmpty
          ? _buildContentScreen(_sections[_selectedIndex])
          : const Center(child: Text('No content available')),
    );
  }
}
