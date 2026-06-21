import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/payment_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'home_screen.dart';

/// Layar untuk menampilkan status transaksi.
///
/// Memanggil API check status saat pertama kali dimuat.
/// Tombol "Refresh" untuk mengecek ulang, dan "Kembali ke Beranda"
/// untuk memulai transaksi baru.
class StatusScreen extends StatefulWidget {
  const StatusScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _paymentService = PaymentService();
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  /// Mengambil status transaksi dari backend
  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _paymentService.checkStatus(
        transactionId: widget.transactionId,
      );
      setState(() {
        _transaction = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Format nominal ke format Rupiah
  String _formatRupiah(double value) {
    final formatted = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(formatted[i]);
    }
    return 'Rp $buffer';
  }

  /// Ikon berdasarkan status transaksi
  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return Icons.check_circle;
      case 'failed':
      case 'error':
        return Icons.error;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Transaksi'),
        // Sembunyikan tombol back agar pengguna tidak kembali
        // ke layar konfirmasi yang sudah diproses
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // State loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // State error
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat status',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Coba Lagi',
            onPressed: _fetchStatus,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Kembali ke Beranda',
            onPressed: () => _goHome(),
          ),
        ],
      );
    }

    // State sukses
    final transaction = _transaction!;

    return Column(
      children: [
        const Spacer(),

        // Ikon status
        Icon(
          _statusIcon(transaction.status),
          size: 80,
          color: _statusColor(transaction.status),
        ),
        const SizedBox(height: 24),

        // Badge status
        StatusBadge(status: transaction.status),
        const SizedBox(height: 32),

        // Detail transaksi
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(label: 'ID Transaksi', value: transaction.transactionId),
                const Divider(height: 20),
                _InfoRow(
                  label: 'Nominal',
                  value: _formatRupiah(transaction.amount),
                ),
                const Divider(height: 20),
                _InfoRow(
                  label: 'Metode',
                  value: transaction.method == 'QRIS'
                      ? 'QRIS'
                      : 'Transfer Bank',
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Tombol refresh
        PrimaryButton(
          label: 'Refresh Status',
          onPressed: _fetchStatus,
        ),
        const SizedBox(height: 12),

        // Tombol kembali ke beranda
        OutlinedButton(
          onPressed: _goHome,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Buat Transaksi Baru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}

/// Baris informasi untuk menampilkan label dan nilai
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
