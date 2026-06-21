import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/payment_service.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'payment_confirmation_screen.dart';
import 'qr_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    _DummyScreen(title: 'Pay'), // Not normally accessed via index, it's a FAB
    _DummyScreen(title: 'Dompet'),
    _DummyScreen(title: 'Saya'),
  ];

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  void _showInputTransactionDialog() {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Input ID Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Salin ID Transaksi dari layar kasir:',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Tempel ID transaksi di sini',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final trxId = controller.text.trim();
                          if (trxId.isEmpty) return;

                          setStateDialog(() => isLoading = true);

                          try {
                            final transaction = await PaymentService().checkStatus(transactionId: trxId);
                            
                            if (!mounted) return;
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentConfirmationScreen(transaction: transaction),
                              ),
                            );
                          } catch (e) {
                            setStateDialog(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                  child: const Text('Cari & Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex, // Keep on current if middle is tapped
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQrScanner,
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        tooltip: 'Scan QR / Bayar',
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Beranda'),
            _buildNavItem(1, Icons.history, Icons.history, 'Riwayat'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(3, Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 'Dompet'),
            _buildNavItem(4, Icons.person, Icons.person_outline, 'Saya'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.6);

    return InkWell(
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
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
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
        style: const TextStyle(
          fontSize: 20,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
