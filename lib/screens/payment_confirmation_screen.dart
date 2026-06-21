import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/payment_service.dart';
import '../widgets/primary_button.dart';
import 'status_screen.dart';

/// Layar konfirmasi pembayaran sebelum diproses.
///
/// Menampilkan ringkasan transaksi (nominal, metode, detail pembayaran).
/// Tombol "Konfirmasi Pembayaran" akan memanggil API untuk memproses
/// pembayaran, lalu navigasi ke layar status.
class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({
    super.key,
    required this.transaction,
  });

  final TransactionModel transaction;

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState
    extends State<PaymentConfirmationScreen> {
  final _paymentService = PaymentService();
  bool _isLoading = false;

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

  /// Label metode pembayaran yang ramah pengguna
  String get _paymentMethodLabel {
    switch (widget.transaction.method) {
      case 'QRIS':
        return 'QRIS';
      case 'BANK_TRANSFER':
        return 'Transfer Bank';
      default:
        return widget.transaction.method;
    }
  }

  /// Ikon metode pembayaran
  IconData get _paymentMethodIcon {
    switch (widget.transaction.method) {
      case 'QRIS':
        return Icons.qr_code_2;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  /// Proses pembayaran dan navigasi ke layar status
  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      await _paymentService.processPayment(
        transactionId: widget.transaction.transactionId,
      );

      if (!mounted) return;

      // Navigasi ke layar status, hapus semua layar sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => StatusScreen(
            transactionId: widget.transaction.transactionId,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trx = widget.transaction;

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Ikon metode pembayaran
            Icon(
              _paymentMethodIcon,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Judul
            Text(
              'Konfirmasi Pembayaran',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Detail transaksi dalam kartu
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _DetailRow(label: 'ID Transaksi', value: trx.transactionId),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Metode',
                      value: _paymentMethodLabel,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Total',
                      value: _formatRupiah(trx.amount),
                      isBold: true,
                    ),
                    if (trx.expiredAt != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Berlaku hingga',
                        value: _formatTime(trx.expiredAt!),
                      ),
                    ],
                    // Tampilkan detail pembayaran dari backend
                    if (trx.paymentDetail != null) ...[
                      const Divider(height: 24),
                      ...trx.paymentDetail!.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _DetailRow(
                            label: e.key.replaceAll('_', ' '),
                            value: e.value.toString(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Tombol konfirmasi
            PrimaryButton(
              label: 'Konfirmasi Pembayaran',
              isLoading: _isLoading,
              onPressed: _processPayment,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Baris detail untuk menampilkan label dan nilai
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

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
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
