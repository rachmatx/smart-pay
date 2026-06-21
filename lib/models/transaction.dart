/// Model data untuk transaksi pembayaran.
///
/// Menggunakan null-safety dan const constructor.
/// Mendukung serialisasi dari/ke JSON untuk komunikasi API.
class TransactionModel {
  const TransactionModel({
    required this.transactionId,
    required this.amount,
    required this.method,
    this.status = 'PENDING',
    this.paymentDetail,
    this.customerRef,
    this.expiredAt,
    this.paidAt,
  });

  /// ID unik transaksi dari backend
  final String transactionId;

  /// Nominal transaksi
  final double amount;

  /// Metode pembayaran: 'QRIS' atau 'BANK_TRANSFER'
  final String method;

  /// Status transaksi: PENDING, SUCCESS, FAILED, EXPIRED
  final String status;

  /// Detail pembayaran (QRIS data atau info rekening bank)
  final Map<String, dynamic>? paymentDetail;

  /// Referensi pelanggan (opsional)
  final String? customerRef;

  /// Waktu kadaluarsa transaksi
  final DateTime? expiredAt;

  /// Waktu pembayaran berhasil
  final DateTime? paidAt;

  /// Buat TransactionModel dari JSON response backend.
  /// Mendukung field `transaction_id` (create/pay) maupun `id` (status).
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paymentDetail: json['payment_detail'] is Map
          ? Map<String, dynamic>.from(json['payment_detail'])
          : null,
      customerRef: json['customer_ref']?.toString(),
      expiredAt: json['expired_at'] != null
          ? DateTime.tryParse(json['expired_at'].toString())
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }

  /// Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'method': method,
      'status': status,
      if (paymentDetail != null) 'payment_detail': paymentDetail,
      if (customerRef != null) 'customer_ref': customerRef,
      if (expiredAt != null) 'expired_at': expiredAt!.toIso8601String(),
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
    };
  }
}
