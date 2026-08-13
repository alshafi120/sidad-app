import '../../domain/entities/customer_dashboard_entity.dart';

class CustomerDashboardModel {
  static CustomerDashboardData fromJson(Map<String, dynamic> json) {
    final merchantsJson = json['merchants'] as List? ?? [];
    final transactionsJson = json['recent_transactions'] as List? ?? [];

    final merchants = merchantsJson.map((m) {
      return CustomerMerchantDebt(
        customerRecordId: m['customer_record_id']?.toString() ?? '',
        merchantId: m['merchant_id']?.toString() ?? '',
        merchantName: m['merchant_name']?.toString() ?? '',
        debtCount: m['debt_count'] as int? ?? 0,
        totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0.0,
        remainingAmount: (m['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        status: m['status']?.toString() ?? 'pending',
      );
    }).toList();

    final recentTransactions = transactionsJson.map((t) {
      return CustomerRecentTransaction(
        id: t['id']?.toString() ?? '',
        merchantId: t['merchant_id']?.toString() ?? '',
        merchantName: t['merchant_name']?.toString() ?? '',
        title: t['title']?.toString() ?? '',
        description: t['description']?.toString(),
        totalAmount: (t['total_amount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (t['paid_amount'] as num?)?.toDouble() ?? 0.0,
        remainingAmount: (t['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        status: t['status']?.toString() ?? 'pending',
        createdAt: t['created_at'] != null
            ? DateTime.tryParse(t['created_at']!) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();

    return CustomerDashboardData(
      totalDebts: (json['total_debts'] as num?)?.toDouble() ?? 0.0,
      settledDebts: (json['settled_debts'] as num?)?.toDouble() ?? 0.0,
      pendingDebts: (json['pending_debts'] as num?)?.toDouble() ?? 0.0,
      merchants: merchants,
      recentTransactions: recentTransactions,
    );
  }
}
