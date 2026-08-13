/// Debt repository interface.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/debt_entity.dart';

abstract class DebtRepository {
  Future<Either<Failure, List<Debt>>> getDebts({
    int page = 1,
    String? status,
    String? customerId,
  });
  Future<Either<Failure, Debt>> getDebtById(String id);
  Future<Either<Failure, Debt>> createDebt({
    required String customerId,
    required double amount,
    String? description,
    String? dueDate,
  });
}
