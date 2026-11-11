import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';
import '../widgets/primary_button.dart';
import 'main_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  final _paymentService = PaymentService();
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fetchStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _paymentService.checkStatus(
        transactionId: widget.transactionId,
      );
      if (!mounted) return;
      setState(() {
        _transaction = result;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    return 'Rp $buffer';
  }

  bool get _isSuccess {
    final status = _transaction?.status.toLowerCase() ?? '';
    return status == 'paid' || status == 'success';
  }

  bool get _isFailed {
    final status = _transaction?.status.toLowerCase() ?? '';
    return status == 'failed' || status == 'error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.primaryColor, // DANA blue background for success
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? _buildErrorState()
          : _buildSuccessState(),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: AppTheme.error),
          const SizedBox(height: 24),
          const Text(
            'Koneksi Gagal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          PrimaryButton(label: 'Coba Lagi', onPressed: _fetchStatus),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _goHome,
            child: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final transaction = _transaction!;
    final color = _isSuccess
        ? AppTheme.success
        : (_isFailed ? AppTheme.error : Colors.amber);
    final icon = _isSuccess
        ? Icons.check_circle_rounded
        : (_isFailed ? Icons.cancel_rounded : Icons.hourglass_empty_rounded);
    final title = _isSuccess
        ? 'Pembayaran Berhasil!'
        : (_isFailed ? 'Pembayaran Gagal' : 'Menunggu Pembayaran');

    return Stack(
      children: [
        // For failed or pending, override the blue background
        if (!_isSuccess)
          Positioned.fill(child: Container(color: AppTheme.background)),

        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 64, color: color),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isSuccess
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRupiah(transaction.amount),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _isSuccess
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Receipt Card (DANA style)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Penyedia',
                              value: 'SmartPay System',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFFF1F5F9)),
                            ),
                            _InfoRow(
                              label: 'ID Transaksi',
                              value: transaction.transactionId,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFFF1F5F9)),
                            ),
                            _InfoRow(
                              label: 'Status',
                              value: transaction.status,
                              valueColor: color,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFFF1F5F9)),
                            ),
                            _InfoRow(
                              label: 'Metode',
                              value: transaction.method == 'QRIS'
                                  ? 'QRIS'
                                  : 'Transfer Bank',
                            ),
                            if (transaction.customerRef != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFF1F5F9)),
                              ),
                              _InfoRow(
                                label: 'Catatan',
                                value: transaction.customerRef!,
                              ),
                            ],
                            if (transaction.paidAt != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFF1F5F9)),
                              ),
                              _InfoRow(
                                label: 'Waktu',
                                value: _formatTime(transaction.paidAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSuccess && !_isFailed) ...[
                  PrimaryButton(
                    label: 'Refresh Status',
                    onPressed: _fetchStatus,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _goHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final d = dt.toUtc().add(const Duration(hours: 7));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
