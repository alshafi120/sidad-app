/// Dashboard repository interface.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../presentation/providers/dashboard_provider.dart'; // To get DashboardData

abstract class DashboardRepository {
  Future<Either<Failure, DashboardData>> getDashboardSummary();
}
