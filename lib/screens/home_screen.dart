import 'package:flutter/material.dart';

import '../services/payment_service.dart';
import '../widgets/amount_input.dart';
import '../widgets/primary_button.dart';
import 'payment_confirmation_screen.dart';

/// Layar utama untuk membuat transaksi baru.
///
/// Pengguna memasukkan nominal, memilih metode pembayaran (QRIS / Transfer Bank),
/// lalu menekan tombol untuk membuat transaksi. Setelah berhasil, navigasi ke
/// layar konfirmasi pembayaran.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  final _customerRefController = TextEditingController();
  final _paymentService = PaymentService();
  String _selectedMethod = 'QRIS';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _customerRefController.dispose();
    super.dispose();
  }

  /// Mengambil nilai nominal murni (tanpa titik pemisah)
  double _parseAmount() {
    final raw = _amountController.text.replaceAll('.', '');
    return double.tryParse(raw) ?? 0.0;
  }

  /// Membuat transaksi baru dan navigasi ke konfirmasi pembayaran
  Future<void> _createTransaction() async {
    final amount = _parseAmount();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = await _paymentService.createTransaction(
        amount: amount,
        method: _selectedMethod,
        customerRef: _customerRefController.text.trim().isNotEmpty
            ? _customerRefController.text.trim()
            : null,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(
            transaction: transaction,
          ),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPay'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Buat Transaksi Baru',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan nominal dan pilih metode pembayaran.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Input nominal
            Text(
              'Nominal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AmountInput(controller: _amountController),
            const SizedBox(height: 24),

            // Referensi pelanggan (opsional)
            Text(
              'Referensi Pelanggan (opsional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerRefController,
              decoration: InputDecoration(
                hintText: 'Contoh: INV-2026-001',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pilihan metode pembayaran
            Text(
              'Metode Pembayaran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MethodCard(
                    icon: Icons.qr_code_2,
                    label: 'QRIS',
                    isSelected: _selectedMethod == 'QRIS',
                    onTap: () => setState(() => _selectedMethod = 'QRIS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MethodCard(
                    icon: Icons.account_balance,
                    label: 'Transfer Bank',
                    isSelected: _selectedMethod == 'BANK_TRANSFER',
                    onTap: () =>
                        setState(() => _selectedMethod = 'BANK_TRANSFER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Tombol buat transaksi
            PrimaryButton(
              label: 'Buat Transaksi',
              isLoading: _isLoading,
              onPressed: _createTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu pilihan metode pembayaran
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
