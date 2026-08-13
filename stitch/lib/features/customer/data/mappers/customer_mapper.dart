/// Mapper for CustomerModel to Customer Entity.
library;

import '../../domain/entities/customer_entity.dart';
import '../models/customer_model.dart';

class CustomerMapper {
  static Customer toEntity(CustomerModel model) {
    return Customer(
      id: model.id,
      userId: model.userId,
      name: model.name,
      phone: model.phone,
      notes: model.notes,
      totalDebt: model.totalDebt ?? 0.0,
      paidAmount: model.paidAmount ?? 0.0,
      debtCount: model.debtCount ?? 0,
      createdAt: model.createdAt != null
          ? DateTime.tryParse(model.createdAt!) ?? DateTime.now()
          : DateTime.now(),
      isSynced: model.isSynced,
      offlineId: model.offlineId,
    );
  }

  static CustomerModel toModel(Customer entity) {
    return CustomerModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      phone: entity.phone,
      notes: entity.notes,
      totalDebt: entity.totalDebt,
      paidAmount: entity.paidAmount,
      debtCount: entity.debtCount,
      createdAt: entity.createdAt.toIso8601String(),
      isSynced: entity.isSynced,
      offlineId: entity.offlineId,
    );
  }
}
