import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/merchant_config.dart';
import '../services/payment_service.dart';
import '../services/server_probe.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.config, this.probe});
  final MerchantConfig? config;
  final ServerProbe? probe;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MerchantConfig get _config => widget.config ?? MerchantConfig.instance;
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(text: _config.settings.baseUrl);
  late final _key = TextEditingController(text: _config.settings.apiKey);
  bool _obscure = true, _busy = false, _success = false;
  String? _message;

  @override
  void dispose() {
    _address.dispose();
    _key.dispose();
    super.dispose();
  }

  void _edited(String _) {
    if (_message != null) setState(() => _message = null);
  }

  ServerSettings? _candidate() {
    if (!_form.currentState!.validate()) return null;
    return ServerSettings.validated(_address.text, _key.text);
  }

  Future<void> _testConnection() async {
    if (_busy) return;
    final settings = _candidate();
    if (settings == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final message = await (widget.probe ?? ServerProbe()).check(settings);
      if (mounted) {
        setState(() {
          _message = message;
          _success = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = error is PaymentConnectionException
              ? error.message
              : 'Koneksi belum dapat diperiksa. Coba kembali.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final settings = _candidate();
    if (settings == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gunakan konfigurasi ini?'),
        content: SingleChildScrollView(
          child: Text(
            '${settings.baseUrl}\n\nRiwayat dan layar pembayaran dimuat ulang. Tagihan pada server sebelumnya tetap tersimpan di sana.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan server'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _config.save(settings);
      if (mounted) {
        setState(() {
          _message = 'Konfigurasi tersimpan. Server ini sekarang aktif.';
          _success = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Konfigurasi belum tersimpan. Server sebelumnya tetap aktif. Coba lagi.';
          _success = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFDCE5ED)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x070F2942),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final active = _config.settings;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            children: [
              Text('Saya', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              const Text(
                'Kelola koneksi Smart Pay Anda.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.dns_outlined,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Server aktif',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      active.baseUrl,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          active.local ? 'Jaringan lokal' : 'Server online',
                          icon: active.local ? Icons.wifi : Icons.public,
                        ),
                        _Badge(
                          active.configured
                              ? 'API key tersimpan'
                              : 'Belum dikonfigurasi',
                          icon: active.configured
                              ? Icons.key_outlined
                              : Icons.settings_outlined,
                        ),
                      ],
                    ),
                    if (_config.revision > 0) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Konfigurasi tersimpan dan langsung digunakan.',
                        style: TextStyle(color: Color(0xFF166534)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_config.loadError != null) ...[
                Text(
                  _config.loadError!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 16),
              ],
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Konfigurasi server',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih Payment API online atau server laptop. Tidak perlu build ulang untuk berpindah server.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('server-address'),
                      controller: _address,
                      enabled: !_busy,
                      onChanged: _edited,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Payment API',
                        hintText: 'http://192.168.1.10:3000',
                        helperText: 'Tanpa /api/transactions atau /health',
                        helperMaxLines: 2,
                        errorMaxLines: 8,
                      ),
                      validator: (value) {
                        try {
                          normalizeServerUrl(value ?? '');
                          return null;
                        } on FormatException catch (e) {
                          return e.message;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('merchant-key'),
                      controller: _key,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      onChanged: _edited,
                      decoration: InputDecoration(
                        labelText: 'API key merchant',
                        helperText: 'Sama dengan API_KEY pada Payment API.',
                        helperMaxLines: 2,
                        errorMaxLines: 8,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure
                              ? 'Tampilkan API key'
                              : 'Sembunyikan API key',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final key = value?.trim() ?? '';
                        return key.isEmpty ||
                                key.length > 512 ||
                                RegExp(r'[\x00-\x20\x7f]').hasMatch(key)
                            ? 'Isi API key yang valid tanpa spasi atau baris baru.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'API key disimpan pada penyimpanan aman perangkat. Jangan isi secret webhook di sini.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _testConnection,
                      icon: const Icon(Icons.network_check),
                      label: const Text('Uji koneksi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Simpan konfigurasi'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _success
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menghubungkan ke laptop',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gunakan Wi-Fi yang sama, IP laptop, dan port Payment API (biasanya 3000). localhost di HP menunjuk HP itu sendiri; 10.0.2.2 hanya untuk emulator.',
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Server online menggunakan HTTPS. HTTP tersedia untuk jaringan lokal. Pengaturan bisa disimpan meski server sedang tidak menyala.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Smart Pay 1.0.1 • Pengujian pembayaran\nMengganti alamat server tidak mengaktifkan integrasi bank nyata.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF135C94)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF135C94),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
