import 'package:flutter/material.dart';

import '../state.dart';
import 'kassa.dart';
import 'receipts.dart';
import 'top.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _receiptsKey = GlobalKey<ReceiptsScreenState>();
  final _topKey = GlobalKey<TopScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const KassaScreen(),
          TopScreen(key: _topKey),
          ReceiptsScreen(key: _receiptsKey),
          const _SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 1) _topKey.currentState?.reload();
          if (i == 2) _receiptsKey.currentState?.reload();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Kassa'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Top'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Cheklar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Sozlama'),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlama')),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.dns_outlined), title: const Text('Server'), subtitle: Text(app.baseUrl)),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text('Foydalanuvchi'), subtitle: Text(app.user)),
          ListTile(
              leading: const Icon(Icons.warehouse_outlined),
              title: const Text('Ombor'),
              subtitle: Text(app.warehouseName)),
          ListTile(
              leading: const Icon(Icons.point_of_sale), title: const Text('Kassa (KKM)'), subtitle: Text(app.kkmName)),
          const Divider(),
          ListenableBuilder(
            listenable: app,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mavzu'),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('Avto'), icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light, label: Text('Kunduzgi'), icon: Icon(Icons.light_mode_outlined)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Tungi'), icon: Icon(Icons.dark_mode_outlined)),
                    ],
                    selected: {app.themeMode},
                    onSelectionChanged: (s) => app.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Bluetooth skaner'),
            subtitle: Text(
                'Skanerni telefon Bluetooth sozlamalaridan klaviatura (HID) sifatida ulang. Kassa ekranida qidiruv maydoni tanlangan bo\'lsa, skanerlangan shtrix-kod tovarni o\'zi savatga qo\'shadi.'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Chiqish'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Chiqishni tasdiqlang'),
                  content: const Text('Savatdagi tovarlar o\'chadi.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Bekor qilish')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Chiqish')),
                  ],
                ),
              );
              if (ok == true) await app.signOut();
            },
          ),
        ],
      ),
    );
  }
}
