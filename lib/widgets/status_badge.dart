import 'package:flutter/material.dart';

/// Badge berwarna untuk menampilkan status transaksi.
///
/// Warna disesuaikan berdasarkan status: pending (kuning), paid (hijau), failed (merah).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tentukan warna dan label berdasarkan status
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Berhasil';
        break;
      case 'failed':
      case 'error':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Gagal';
        break;
      case 'pending':
      default:
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        label = 'Menunggu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
