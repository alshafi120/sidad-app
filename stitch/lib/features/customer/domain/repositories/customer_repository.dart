/// Customer repository interface.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers({
    int page = 1,
    String? search,
  });
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, Customer>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  });
  Future<Either<Failure, Customer>> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, Customer>> linkCustomerAccount(
    String id, {
    String? phone,
    String? linkCode,
  });
  Future<Either<Failure, void>> linkMerchant(String merchantCode);
}
