/// Debt data model.
library;

class DebtModel {
  final String id;
  final String customerId;
  final String? customerName;
  final double amount;
  final double paidAmount;
  final String? description;
  final String status;
  final String? createdAt;
  final String? dueDate;

  const DebtModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.amount,
    required this.paidAmount,
    this.description,
    required this.status,
    this.createdAt,
    this.dueDate,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer'] != null
          ? json['customer']['full_name'] as String?
          : null,
      amount:
          (json['total_amount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
      dueDate: json['due_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'paid_amount': paidAmount,
      if (description != null) 'description': description,
      'status': status,
      if (dueDate != null) 'due_date': dueDate,
    };
  }
}
