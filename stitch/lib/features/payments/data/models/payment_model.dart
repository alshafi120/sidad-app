/// Payment data model.
library;

class PaymentModel {
  final String id;
  final String debtId;
  final double amount;
  final String? receiptNumber;
  final String? notes;
  final String? createdAt;

  const PaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    this.receiptNumber,
    this.notes,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      debtId: json['debt_id']?.toString() ?? '',
      amount: ((json['amount'] as num?)?.toDouble() ?? 0.0) / 100.0,
      receiptNumber:
          json['transaction_reference'] as String? ??
          json['receipt_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['paid_at'] as String? ?? json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': (amount * 100).round(),
      if (receiptNumber != null) 'transaction_reference': receiptNumber,
      if (notes != null) 'notes': notes,
    };
  }
}
