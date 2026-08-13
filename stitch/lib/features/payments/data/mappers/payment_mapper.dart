/// Mapper for PaymentModel to Payment Entity.
library;

import '../../domain/entities/payment_entity.dart';
import '../models/payment_model.dart';

class PaymentMapper {
  static Payment toEntity(PaymentModel model) {
    return Payment(
      id: model.id,
      debtId: model.debtId,
      amount: model.amount,
      receiptNumber: model.receiptNumber,
      notes: model.notes,
      createdAt: model.createdAt != null
          ? DateTime.tryParse(model.createdAt!) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static PaymentModel toModel(Payment entity) {
    return PaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amount: entity.amount,
      receiptNumber: entity.receiptNumber,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
