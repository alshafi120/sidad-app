/// Mapper for DebtModel to Debt Entity.
library;

import '../../domain/entities/debt_entity.dart';
import '../models/debt_model.dart';

class DebtMapper {
  static Debt toEntity(DebtModel model) {
    DebtStatusEnum status;
    switch (model.status) {
      case 'completed':
      case 'paid':
        status = DebtStatusEnum.paid;
        break;
      case 'overdue':
        status = DebtStatusEnum.overdue;
        break;
      case 'partially_paid':
        status = DebtStatusEnum.partiallyPaid;
        break;
      case 'pending':
      case 'approved':
      case 'active':
      default:
        status = DebtStatusEnum.pending;
    }

    return Debt(
      id: model.id,
      customerId: model.customerId,
      customerName: model.customerName ?? 'Unknown',
      amount: model.amount,
      paidAmount: model.paidAmount,
      description: model.description,
      status: status,
      createdAt: model.createdAt != null
          ? DateTime.tryParse(model.createdAt!) ?? DateTime.now()
          : DateTime.now(),
      dueDate: model.dueDate != null ? DateTime.tryParse(model.dueDate!) : null,
    );
  }

  static DebtModel toModel(Debt entity) {
    String status;
    switch (entity.status) {
      case DebtStatusEnum.paid:
        status = 'completed';
        break;
      case DebtStatusEnum.overdue:
        status = 'overdue';
        break;
      case DebtStatusEnum.partiallyPaid:
        status = 'partially_paid';
        break;
      case DebtStatusEnum.pending:
        status = 'pending';
    }

    return DebtModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      amount: entity.amount,
      paidAmount: entity.paidAmount,
      description: entity.description,
      status: status,
      createdAt: entity.createdAt.toIso8601String(),
      dueDate: entity.dueDate?.toIso8601String(),
    );
  }
}
