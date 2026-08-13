/// Customer data model.
library;

class CustomerModel {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String? email;
  final String? nationalId;
  final String? address;
  final String? notes;
  final double? totalDebt;
  final double? paidAmount;
  final int? debtCount;
  final String? createdAt;
  final bool isSynced;
  final String? offlineId;

  const CustomerModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.nationalId,
    this.address,
    this.notes,
    this.totalDebt,
    this.paidAmount,
    this.debtCount,
    this.createdAt,
    this.isSynced = true,
    this.offlineId,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      nationalId: json['national_id'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      totalDebt: (json['total_debt'] as num?)?.toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble(),
      debtCount: json['debt_count'] as int?,
      createdAt: json['created_at'] as String?,
      isSynced: json['is_synced'] == null
          ? true
          : (json['is_synced'] == 1 || json['is_synced'] == true),
      offlineId: json['offline_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'full_name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (nationalId != null) 'national_id': nationalId,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      if (offlineId != null) 'offline_id': offlineId,
    };
  }
}
