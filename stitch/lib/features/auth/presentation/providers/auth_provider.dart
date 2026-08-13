/// Auth state management with Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Repository Provider ──────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
  );
});

// ── Auth State ───────────────────────────────────────────────────────
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool otpSent;
  final bool requiresVerification;
  final UserRole? selectedRole;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.otpSent = false,
    this.requiresVerification = false,
    this.selectedRole,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? otpSent,
    bool? requiresVerification,
    UserRole? selectedRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

// ── Auth Notifier ────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repository.login(email, password);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) =>
          state = state.copyWith(status: AuthStatus.authenticated, user: user),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        requiresVerification: true,
      ),
    );
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      final result = await _repository.getCurrentUser();
      result.fold(
        (failure) async {
          // Network error — try to use cached user data
          final cachedResult = await _repository.getCachedUser();
          cachedResult.fold(
            (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
            (user) => state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
            ),
          );
        },
        (user) => state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp(String identifier) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repository.sendOtp(identifier);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (_) => state = state.copyWith(
        status: AuthStatus.authenticated,
        otpSent: true,
      ),
    );
  }

  Future<void> verifyOtp(String identifier, String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repository.verifyOtp(identifier, otp);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        requiresVerification: false,
      ),
    );
  }

  Future<void> setRole(UserRole role) async {
    state = state.copyWith(selectedRole: role);
    await _repository.setUserRole(role);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated, error: null);
  }
}

// ── Provider ─────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
