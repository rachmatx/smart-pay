import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';
import 'qr_scanner_screen.dart';
import 'send_money_screen.dart';

double globalTopUpTotal = 0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 1250000;
  List<TransactionModel> _transactions = [];
  bool _isLoadingFeed = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await PaymentService().fetchTransactionHistory();
      if (mounted) {
        setState(() {
          _transactions = data;
          
          double spent = 0;
          for (var tx in _transactions) {
            if (tx.status == 'SUCCESS') {
              spent += tx.amount;
            }
          }
          _balance = 1250000 + globalTopUpTotal - spent;
          
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFeed = false;
        });
      }
    }
  }

  String _formatRupiah(double value) {
    final formatted = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(formatted[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildServicesGrid(),
                _buildPromoBanner(),
                _buildFeed(),
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryColor,
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text(
            'SmartPay',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Balance Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatRupiah(_balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Isi Saldo'),
                            content: const Text('Apakah Anda ingin mengisi saldo sebesar Rp 500.000?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    globalTopUpTotal += 500000;
                                  });
                                  _fetchTransactions(); // trigger balance recalculation
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Isi saldo berhasil!')),
                                  );
                                },
                                child: const Text('Top Up'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Top Up',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionBtn(
                      icon: Icons.qr_code_scanner,
                      label: 'Pindai',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        );
                        _fetchTransactions(); // REFRESH balance and feed!
                      },
                    ),
                    _QuickActionBtn(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Isi Saldo',
                      onTap: () {
                        setState(() {
                          globalTopUpTotal += 500000;
                        });
                        _fetchTransactions();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Isi saldo Rp 500.000 berhasil!')),
                        );
                      },
                    ),
                    _QuickActionBtn(
                      icon: Icons.send_outlined,
                      label: 'Kirim',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SendMoneyScreen()),
                        );
                        _fetchTransactions(); // REFRESH balance and feed!
                      },
                    ),
                    _QuickActionBtn(
                      icon: Icons.call_received,
                      label: 'Minta',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {'icon': Icons.phone_android, 'label': 'Pulsa & Data'},
      {'icon': Icons.bolt, 'label': 'Listrik'},
      {'icon': Icons.water_drop, 'label': 'Air PDAM'},
      {'icon': Icons.games, 'label': 'Games'},
      {'icon': Icons.tv, 'label': 'Internet & TV'},
      {'icon': Icons.money, 'label': 'E-Money'},
      {'icon': Icons.health_and_safety, 'label': 'BPJS'},
      {'icon': Icons.grid_view, 'label': 'Lainnya'},
    ];

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service['icon'] as IconData,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Info & Promo Spesial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Promo Spesial Bulan Ini!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cashback hingga 50% untuk pembayaran pakai SmartPay.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  setState(() => _isLoadingFeed = true);
                  _fetchTransactions();
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingFeed)
            const Center(child: CircularProgressIndicator())
          else if (_transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada aktivitas'),
              ),
            )
          else
            ..._transactions.map((tx) {
              final isPositive = false; // Smart Pay acts as the payer here
              final icon = tx.method == 'QRIS' ? Icons.qr_code : Icons.account_balance;
              final title = tx.method == 'QRIS' ? 'Pembayaran QRIS' : 'Transfer Bank';
              
              // format date
              final d = tx.createdAt?.toLocal();
              final dateStr = d != null ? '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}' : 'Waktu tidak diketahui';
              
              return Column(
                children: [
                  _FeedItem(
                    icon: icon,
                    title: title,
                    date: dateStr,
                    amount: '-Rp ${_formatRupiah(tx.amount)}',
                    isPositive: isPositive,
                  ),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final bool isPositive;

  const _FeedItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.textSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppTheme.success : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

