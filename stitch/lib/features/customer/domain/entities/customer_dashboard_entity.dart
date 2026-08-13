import 'package:equatable/equatable.dart';

class CustomerDashboardData extends Equatable {
  final double totalDebts;
  final double settledDebts;
  final double pendingDebts;
  final List<CustomerMerchantDebt> merchants;
  final List<CustomerRecentTransaction> recentTransactions;

  const CustomerDashboardData({
    required this.totalDebts,
    required this.settledDebts,
    required this.pendingDebts,
    required this.merchants,
    required this.recentTransactions,
  });

  @override
  List<Object?> get props => [
    totalDebts,
    settledDebts,
    pendingDebts,
    merchants,
    recentTransactions,
  ];
}

class CustomerMerchantDebt extends Equatable {
  final String customerRecordId;
  final String merchantId;
  final String merchantName;
  final int debtCount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;

  const CustomerMerchantDebt({
    required this.customerRecordId,
    required this.merchantId,
    required this.merchantName,
    required this.debtCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  @override
  List<Object?> get props => [
    customerRecordId,
    merchantId,
    merchantName,
    debtCount,
    totalAmount,
    paidAmount,
    remainingAmount,
    status,
  ];
}

class CustomerRecentTransaction extends Equatable {
  final String id;
  final String merchantId;
  final String merchantName;
  final String title;
  final String? description;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime createdAt;

  const CustomerRecentTransaction({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    merchantId,
    merchantName,
    title,
    description,
    totalAmount,
    paidAmount,
    remainingAmount,
    status,
    createdAt,
  ];
}
