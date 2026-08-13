/// Payment domain entity.
library;

import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String debtId;
  final double amount;
  final String? receiptNumber;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    this.receiptNumber,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    debtId,
    amount,
    receiptNumber,
    notes,
    createdAt,
  ];
}
