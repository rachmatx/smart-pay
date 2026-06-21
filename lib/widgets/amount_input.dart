import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input untuk nominal uang dengan format Rupiah.
///
/// Menampilkan prefix "Rp" dan memformat angka secara otomatis
/// saat pengguna mengetik.
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    this.hintText = 'Masukkan nominal',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      inputFormatters: [
        // Hanya izinkan angka
        FilteringTextInputFormatter.digitsOnly,
        // Format dengan pemisah ribuan
        _ThousandsSeparatorFormatter(),
      ],
      decoration: InputDecoration(
        prefixText: 'Rp ',
        prefixStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}

/// Formatter untuk menambahkan titik sebagai pemisah ribuan.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Hapus semua titik yang ada, lalu format ulang
    final digits = newValue.text.replaceAll('.', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
