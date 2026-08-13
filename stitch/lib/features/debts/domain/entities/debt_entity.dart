/// Debt domain entity.
library;

import 'package:equatable/equatable.dart';

enum DebtStatusEnum { pending, paid, overdue, partiallyPaid }

class Debt extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final String? description;
  final DebtStatusEnum status;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Debt({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.paidAmount = 0,
    this.description,
    this.status = DebtStatusEnum.pending,
    required this.createdAt,
    this.dueDate,
  });

  double get remaining => amount - paidAmount;
  bool get isPaid => status == DebtStatusEnum.paid;
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid;

  @override
  List<Object?> get props => [
    id,
    customerId,
    amount,
    paidAmount,
    status,
    createdAt,
    dueDate,
  ];
}
