import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await PaymentService().fetchTransactionHistory();
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil riwayat transaksi')),
        );
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

  String _formatIndonesianDate(DateTime d) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final timeZone = d.timeZoneName; // Akan mendeteksi WIB/WITA/WIT jika HP disetting ke regional Indonesia
    return '${d.day} ${months[d.month - 1]} ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $timeZone';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada riwayat transaksi', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final icon = tx.method == 'QRIS' ? Icons.qr_code : Icons.account_balance;
                      final title = tx.method == 'QRIS' ? 'Pembayaran QRIS' : 'Transfer Bank';
                      
                      final d = tx.createdAt?.toLocal();
                      final dateStr = d != null 
                          ? _formatIndonesianDate(d)
                          : 'Waktu tidak diketahui';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: AppTheme.primaryColor),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('ID: ${tx.transactionId.length > 8 ? tx.transactionId.substring(0, 8) : tx.transactionId}...'),
                              const SizedBox(height: 2),
                              Text(dateStr, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-Rp ${_formatRupiah(tx.amount)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tx.status == 'SUCCESS' ? AppTheme.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tx.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tx.status == 'SUCCESS' ? AppTheme.success : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
