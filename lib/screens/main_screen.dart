import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/merchant_config.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';

int _balanceScopeRevision = -1;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    if (_balanceScopeRevision != MerchantConfig.instance.revision) {
      globalTopUpTotal = 0;
      _balanceScopeRevision = MerchantConfig.instance.revision;
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    _DummyScreen(title: 'Pay'), // Not normally accessed via index, it's a FAB
    _DummyScreen(title: 'Dompet'),
    const ProfileScreen(),
  ];

  void _openQrScanner() {
    if (!MerchantConfig.instance.settings.configured) {
      setState(() => _currentIndex = 4);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi dan simpan konfigurasi server terlebih dahulu.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex == 2
            ? 0
            : _currentIndex, // Keep on current if middle is tapped
        children: MerchantConfig.instance.settings.configured
            ? _screens
            : [
                const Center(
                  child: Text('Atur server di halaman Saya untuk melanjutkan.'),
                ),
                const Center(
                  child: Text('Atur server di halaman Saya untuk melanjutkan.'),
                ),
                const SizedBox.shrink(),
                const Center(
                  child: Text('Atur server di halaman Saya untuk melanjutkan.'),
                ),
                const ProfileScreen(),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQrScanner,
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        tooltip: 'Scan QR / Bayar',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 88,
        color: AppTheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Beranda'),
            _buildNavItem(1, Icons.history, Icons.history, 'Riwayat'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              3,
              Icons.account_balance_wallet,
              Icons.account_balance_wallet_outlined,
              'Dompet',
            ),
            _buildNavItem(4, Icons.person, Icons.person_outline, 'Saya'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppTheme.primaryColor
        : AppTheme.textSecondary.withValues(alpha: 0.6);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DummyScreen extends StatelessWidget {
  final String title;
  const _DummyScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Halaman $title\n(Segera Hadir)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, color: AppTheme.textSecondary),
      ),
    );
  }
}
