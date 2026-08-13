/// Customer domain entity.
library;

import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String? notes;
  final double totalDebt;
  final double paidAmount;
  final int debtCount;
  final DateTime createdAt;
  final bool isSynced;
  final String? offlineId;

  const Customer({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.notes,
    this.totalDebt = 0,
    this.paidAmount = 0,
    this.debtCount = 0,
    required this.createdAt,
    this.isSynced = true,
    this.offlineId,
  });

  double get remainingDebt => totalDebt - paidAmount;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    phone,
    notes,
    totalDebt,
    paidAmount,
    debtCount,
    createdAt,
    isSynced,
    offlineId,
  ];
}
