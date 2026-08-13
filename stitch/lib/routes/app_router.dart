/// GoRouter configuration with merchant/customer navigation shells.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/customer/presentation/screens/add_customer_screen.dart';
import '../features/customer/presentation/screens/customer_dashboard_screen.dart';
import '../features/customer/presentation/screens/customer_list_screen.dart';
import '../features/customer/presentation/screens/customer_view_screen.dart';
import '../features/debts/presentation/screens/add_debt_screen.dart';
import '../features/debts/presentation/screens/debt_details_screen.dart';
import '../features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/register_payment_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import '../shared/layouts/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, state) => OtpScreen(contact: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (_, __) => const RoleSelectionScreen(),
    ),

    // ── Merchant Shell ──────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/merchant-dashboard',
              builder: (_, __) => const MerchantDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customers',
              builder: (_, __) => const CustomerListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Customer Shell ──────────────────────────────────────────
    GoRoute(
      path: '/customer-dashboard',
      builder: (_, state) {
        final code = state.uri.queryParameters['code'];
        return CustomerDashboardScreen(prefilledMerchantCode: code);
      },
    ),
    GoRoute(
      path: '/join',
      builder: (_, state) {
        final code = state.uri.queryParameters['code'];
        return CustomerDashboardScreen(prefilledMerchantCode: code);
      },
    ),

    // ── Detail Routes ───────────────────────────────────────────
    GoRoute(
      path: '/add-customer',
      builder: (_, __) => const AddCustomerScreen(),
    ),
    GoRoute(
      path: '/add-debt',
      builder: (_, state) {
        final customerId = state.extra as String?;
        return AddDebtScreen(prefilledCustomerId: customerId);
      },
    ),
    GoRoute(
      path: '/customer/:id',
      builder: (_, state) =>
          CustomerViewScreen(customerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/debt/:id',
      builder: (_, state) =>
          DebtDetailsScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/register-payment',
      builder: (_, state) {
        final extra = state.extra;
        return RegisterPaymentScreen(
          customerId: extra is String ? extra : null,
        );
      },
    ),
  ],
);
