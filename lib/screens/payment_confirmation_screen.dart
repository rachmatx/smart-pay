import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/primary_button.dart';
import 'pin_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({
    super.key,
    required this.transaction,
  });

  final TransactionModel transaction;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            transaction.method == 'QRIS'
                                ? Icons.qr_code_2_rounded
                                : Icons.account_balance_rounded,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatRupiah(transaction.amount),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            String penyedia = 'SmartPay System';
                            if (transaction.paymentDetail != null) {
                              if (transaction.method == 'QRIS') {
                                penyedia = transaction.paymentDetail!['merchant_name'] ?? 'SmartPay System';
                              } else {
                                final bank = transaction.paymentDetail!['bank_name'] ?? '';
                                final name = transaction.paymentDetail!['merchant_name'] ?? transaction.paymentDetail!['account_holder'] ?? 'SmartPay System';
                                penyedia = bank.isNotEmpty ? '$name ($bank)' : name;
                              }
                            }
                            return _DetailRow(
                              label: 'Penyedia',
                              value: penyedia,
                            );
                          }
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFF1F5F9)),
                        ),
                        _DetailRow(
                          label: 'ID Transaksi',
                          value: transaction.transactionId,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFF1F5F9)),
                        ),
                        _DetailRow(
                          label: 'Metode',
                          value: transaction.method == 'QRIS' ? 'QRIS' : 'Transfer Bank',
                        ),
                        if (transaction.customerRef != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFF1F5F9)),
                          ),
                          _DetailRow(
                            label: 'Catatan',
                            value: transaction.customerRef!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: PrimaryButton(
              label: 'Bayar Sekarang',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinScreen(transaction: transaction),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
