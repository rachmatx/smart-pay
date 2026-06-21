import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';
import 'status_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    super.key,
    required this.transaction,
  });

  final TransactionModel transaction;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  final int _pinLength = 6;
  bool _isLoading = false;
  bool _isError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
          setState(() {
            _pin = '';
            _isError = false;
          });
        }
      });

    // Check biometric after small delay
    Future.delayed(const Duration(milliseconds: 500), _checkBiometric);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final authenticated = await auth.authenticate(
          localizedReason: 'Gunakan sidik jari untuk mengonfirmasi pembayaran',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated) {
          _processPayment();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur biometrik tidak tersedia (Anda sedang menjalankan versi Web/Chrome). Silakan gunakan PIN.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sistem gagal memuat biometrik: ${e.message ?? 'Tidak didukung'}.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _onKeypadPressed(String value) {
    if (_pin.length < _pinLength && !_isLoading && !_isError) {
      setState(() {
        _pin += value;
      });

      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading && !_isError) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    // Simulate network delay for verification
    await Future.delayed(const Duration(milliseconds: 500));

    // Hardcode PIN for prototype purpose (123456 is correct)
    if (_pin == '123456') {
      _processPayment();
    } else {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _shakeController.forward();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    final paymentService = PaymentService();

    try {
      await paymentService.processPayment(
        transactionId: widget.transaction.transactionId,
      );

      if (!mounted) return;

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
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      _shakeController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Title
            const Text(
              'Masukkan PIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PIN Anda untuk konfirmasi (tes: 123456)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),

            // PIN Dots Indicator
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value * (_shakeController.value > 0.5 ? -1 : 1),
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? AppTheme.error
                          : (isFilled ? Colors.white : Colors.white24),
                    ),
                  );
                }),
              ),
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],

            const Spacer(),

            // Custom Keypad
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var j = 1; j <= 3; j++)
                          _KeypadButton(
                            text: '${i * 3 + j}',
                            onTap: () => _onKeypadPressed('${i * 3 + j}'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button (fingerprint)
                      _KeypadButton(
                        icon: Icons.fingerprint,
                        onTap: _checkBiometric,
                      ),
                      _KeypadButton(
                        text: '0',
                        onTap: () => _onKeypadPressed('0'),
                      ),
                      // Backspace button
                      _KeypadButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({
    this.text,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: text != null
              ? Text(
                  text!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                )
              : Icon(
                  icon,
                  size: 32,
                  color: AppTheme.textSecondary,
                ),
        ),
      ),
    );
  }
}
