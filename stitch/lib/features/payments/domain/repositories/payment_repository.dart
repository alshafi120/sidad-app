/// Payment repository interface.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<Payment>>> getPaymentsByDebt(String debtId);
  Future<Either<Failure, Payment>> recordPayment({
    required String debtId,
    required double amount,
    String? receiptNumber,
    String? notes,
  });
}
