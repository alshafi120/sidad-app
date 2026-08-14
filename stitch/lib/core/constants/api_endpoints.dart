/// API endpoint constants — Laravel-compatible REST structure.
library;

abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://16.16.74.244/api',
  );

  // ── Auth ─────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/profile';

  // ── Merchants ────────────────────────────────────────────────────
  static const String merchants = '/merchants';
  static const String merchantDashboard = '/merchants/dashboard';

  // ── Customers ────────────────────────────────────────────────────
  static const String customers = '/customers';
  static String customerById(String id) => '/customers/$id';
  static String linkCustomer(String id) => '/customers/$id/link';
  static const String customerDashboard = '/customer/dashboard';
  static const String linkMerchant = '/customer/link-merchant';

  // ── Debts ────────────────────────────────────────────────────────
  static const String debts = '/debts';
  static String debtById(String id) => '/debts/$id';
  static const String payments = '/payments';
  static String paymentsByDebt(String debtId) => '/debts/$debtId/payments';

  // ── Notifications ────────────────────────────────────────────────
  static const String notifications = '/notifications';
}
