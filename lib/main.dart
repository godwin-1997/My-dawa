import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DawaStore.load();
  runApp(const DawaCareApp());
}

// =========================
// STORAGE
// =========================
class DawaStore {
  static List<Map<String, dynamic>> products = [];
  static List<Map<String, dynamic>> sales = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final productsData = prefs.getString('products');
    final salesData = prefs.getString('sales');

    if (productsData != null) {
      products = List<Map<String, dynamic>>.from(
        (jsonDecode(productsData) as List)
            .map((e) => Map<String, dynamic>.from(e)),
      );
    }

    if (salesData != null) {
      sales = List<Map<String, dynamic>>.from(
        (jsonDecode(salesData) as List)
            .map((e) => Map<String, dynamic>.from(e)),
      );
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(products),
    );

    await prefs.setString(
      'sales',
      jsonEncode(sales),
    );
  }
}

// =========================
// APP
// =========================
class DawaCareApp extends StatelessWidget {
  const DawaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DawaCare POS',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xfff4f8f5),
      ),
      home: const DawaCareHome(),
    );
  }
}

// =========================
// HOME
// =========================
class DawaCareHome extends StatefulWidget {
  const DawaCareHome({super.key});

  @override
  State<DawaCareHome> createState() => _DawaCareHomeState();
}

class _DawaCareHomeState extends State<DawaCareHome> {
  int currentIndex = 0;

  List<Map<String, dynamic>> cart = [];

  String money(num amount) {
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  num get todaySales {
    final now = DateTime.now();

    return DawaStore.sales
        .where((sale) {
          final date = DateTime.parse(sale['date']);

          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<num>(
          0,
          (total, sale) => total + (sale['total'] as num),
        );
  }

  num get todayProfit {
    final now = DateTime.now();

    return DawaStore.sales
        .where((sale) {
          final date = DateTime.parse(sale['date']);

          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<num>(
          0,
          (total, sale) => total + (sale['profit'] as num),
        );
  }

  int get lowStock {
    return DawaStore.products.where((product) {
      return (product['qty'] as num) <= (product['min'] as num);
    }).length;
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboardPage(),
      salesPage(),
      stockPage(),
      reportsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.local_pharmacy),
            SizedBox(width: 8),
            Text(
              'DawaCare POS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Mauzo',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Ripoti',
          ),
        ],
      ),
    );
  }

  // =========================
  // DASHBOARD
  // =========================
  Widget dashboardPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              statCard(
                'Mauzo leo',
                money(todaySales),
                Icons.point_of_sale,
              ),
              statCard(
                'Faida leo',
                money(todayProfit),
                Icons.trending_up,
              ),
              statCard(
                'Dawa',
                DawaStore.products.length.toString(),
                Icons.medication,
              ),
              statCard(
                'Low Stock',
                lowStock.toString(),
                Icons.warning_amber,
              ),
            ],
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muhtasari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Jumla ya dawa: ${DawaStore.products.length}',
                  ),
                  Text(
                    'Stock iliyopo: ${DawaStore.products.fold<num>(0, (a, p) => a + p['qty'])}',
                  ),
                  Text(
                    'Transactions: ${DawaStore.sales.length}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (lowStock > 0)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                title: const Text('Tahadhari ya Stock'),
                subtitle: Text(
                  '$lowStock dawa zina stock ndogo.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // SALES
  // =========================
  Widget salesPage() {
    final total = cart.fold<num>(
      0,
      (sum, item) => sum + (item['price'] as num) * item['qty'],
    );

    return Column(
      children: [
        Expanded(
          child: DawaStore.products.isEmpty
              ? const Center(
                  child: Text(
                    'Hakuna dawa.\nOngeza dawa kwenye Stock.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: DawaStore.products.length,
                  itemBuilder: (context, index) {
                    final product = DawaStore.products[index];

                    final qty = product['qty'] as num;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(
                            Icons.medication,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${product['generic']}\n'
                          '${product['strength']} • Stock: $qty\n'
                          '${money(product['sell'])}',
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: qty > 0
                              ? () => addToCart(product)
                              : null,
                          child: const Text('Ongeza'),
                        ),
                      ),
                    );
                  },
                ),
        ),

        Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Text(
                  'Bidhaa kwenye oda: ${cart.length}',
                ),
                const SizedBox(height: 5),
                Text(
                  money(total),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : completeSale,
                    icon: const Icon(Icons.check),
                    label: const Text('KAMILISHA MAUZO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void addToCart(Map<String, dynamic> product) {
    final existing = cart.where(
      (item) => item['id'] == product['id'],
    );

    if (existing.isEmpty) {
      cart.add({
        'id': product['id'],
        'name': product['name'],
        'qty': 1,
        'price': product['sell'],
        'buy': product['buy'],
      });
    } else {
      final item = existing.first;

      if (item['qty'] < product['qty']) {
        item['qty']++;
      }
    }

    setState(() {});
  }

  Future<void> completeSale() async {
    if (cart.isEmpty) return;

    num total = 0;
    num profit = 0;

    for (final item in cart) {
      final product = DawaStore.products.firstWhere(
        (p) => p['id'] == item['id'],
      );

      if (product['qty'] < item['qty']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock haitoshi: ${product['name']}',
            ),
          ),
        );
        return;
      }

      product['qty'] -= item['qty'];

      total += item['price'] * item['qty'];

      profit +=
          (item['price'] - item['buy']) * item['qty'];
    }

    DawaStore.sales.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'profit': profit,
      'items': cart,
    });

    await DawaStore.save();

    setState(() {
      cart.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mauzo yamehifadhiwa. Faida: ${money(profit)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // =========================
  // STOCK
  // =========================
  Widget stockPage() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DawaStore.products.isEmpty
          ? const Center(
              child: Text(
                'Hakuna dawa kwenye stock.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: DawaStore.products.length,
              itemBuilder: (context, index) {
                final product = DawaStore.products[index];

                final qty = product['qty'] as num;
                final min = product['min'] as num;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: qty <= min
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        Icons.medication,
                        color: qty <= min
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${product['generic']}\n'
                      '${product['strength']} • Batch: ${product['batch']}\n'
                      'Bei: ${money(product['sell'])}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (qty <= min)
                          const Text(
                            'LOW',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: showAddMedicineDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ongeza Dawa'),
      ),
    );
  }

  // =========================
  // ADD MEDICINE
  // =========================
  void showAddMedicineDialog() {
    final name = TextEditingController();
    final generic = TextEditingController();
    final strength = TextEditingController();
    final batch = TextEditingController();
    final expiry = TextEditingController();
    final qty = TextEditingController();
    final min = TextEditingController(text: '5');
    final buy = TextEditingController();
    final sell = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ongeza Dawa'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                input(name, 'Jina la dawa'),
                input(generic, 'Generic / Professional name'),
                input(strength, 'Vipimo / Strength'),
                input(batch, 'Batch Number'),
                input(expiry, 'Expiry Date'),
                input(qty, 'Quantity', number: true),
                input(
                  min,
                  'Low Stock Threshold',
                  number: true,
                ),
                input(
                  buy,
                  'Bei ya Kununua',
                  number: true,
                ),
                input(
                  sell,
                  'Bei ya Kuuza',
                  number: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  return;
                }

                DawaStore.products.add({
                  'id': DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  'name': name.text.trim(),
                  'generic': generic.text.trim(),
                  'strength': strength.text.trim(),
                  'batch': batch.text.trim(),
                  'expiry': expiry.text.trim(),
                  'qty': int.tryParse(qty.text) ?? 0,
                  'min': int.tryParse(min.text) ?? 5,
                  'buy': num.tryParse(buy.text) ?? 0,
                  'sell': num.tryParse(sell.text) ?? 0,
                });

                await DawaStore.save();

                if (context.mounted) {
                  Navigator.pop(context);
                }

                setState(() {});
              },
              child: const Text('Hifadhi'),
            ),
          ],
        );
      },
    );
  }

  Widget input(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // =========================
  // REPORTS
  // =========================
  Widget reportsPage() {
    final totalSales = DawaStore.sales.fold<num>(
      0,
      (total, sale) => total + (sale['total'] as num),
    );

    final totalProfit = DawaStore.sales.fold<num>(
      0,
      (total, sale) => total + (sale['profit'] as num),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ripoti',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        statCard(
          'Jumla ya Mauzo',
          money(totalSales),
          Icons.payments,
        ),

        statCard(
          'Jumla ya Faida',
          money(totalProfit),
          Icons.trending_up,
        ),

        statCard(
          'Transactions',
          DawaStore.sales.length.toString(),
          Icons.receipt_long,
        ),

        const SizedBox(height: 15),

        const Text(
          'Historia ya Mauzo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...DawaStore.sales.reversed.map(
          (sale) {
            final date = DateTime.parse(
              sale['date'],
            );

            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.receipt,
                  color: Colors.green,
                ),
                title: Text(
                  money(sale['total']),
                ),
                subtitle: Text(
                  '${date.day}/${date.month}/${date.year}',
                ),
                trailing: Text(
                  'Faida\n${money(sale['profit'])}',
                  textAlign: TextAlign.right,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
