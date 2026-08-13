/// Auth repository contract.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  });
  Future<Either<Failure, String>> sendOtp(String identifier);
  Future<Either<Failure, User>> verifyOtp(String identifier, String otp);
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> setUserRole(UserRole role);
  Future<Either<Failure, void>> logout();
  Future<bool> isLoggedIn();
  Future<Either<Failure, User>> getCachedUser();
}
