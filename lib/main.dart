import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chain_provider.dart';
import 'screens/home_page.dart';
import 'screens/stats_page.dart';
import 'screens/accounts_page.dart';
import 'screens/settings_page.dart';
import 'screens/add_transaction_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final chainProvider = ChainProvider();
  chainProvider.loadData();

  runApp(
    ChangeNotifierProvider.value(
      value: chainProvider,
      child: const ChainAccountingApp(),
    ),
  );
}

class ChainAccountingApp extends StatelessWidget {
  const ChainAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChainProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: '区块记账',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'sans-serif',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'sans-serif',
          ),
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainShell(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _titles = ['首页', '统计', '账户', '设置'];
  static const _icons = [
    Icons.home_rounded,
    Icons.bar_chart_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.settings_rounded,
  ];

  final _pages = const [
    HomePage(),
    StatsPage(),
    AccountsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'main_fab',
              onPressed: () => _showAddTransaction(context),
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.link_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Chain Accounting',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '区块链记账',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (i) {
              final selected = _currentIndex == i;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ListTile(
                  leading: Icon(
                    _icons[i],
                    color: selected
                        ? const Color(0xFF1565C0)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  title: Text(
                    _titles[i],
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1565C0)
                          : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: const Color(0xFF1565C0).withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<ChainProvider>(
                builder: (context, provider, _) {
                  final valid = provider.verifyChain();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        valid ? Icons.verified : Icons.warning,
                        size: 16,
                        color: valid
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        valid ? '区块链完整性正常' : '区块链完整性异常',
                        style: TextStyle(
                          fontSize: 12,
                          color: valid
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}
