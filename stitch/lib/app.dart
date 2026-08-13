/// Root application widget with theme, localization, and router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/sync/sync_manager.dart';
import 'routes/app_router.dart';

class SidadApp extends ConsumerWidget {
  const SidadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize global background sync manager
    ref.watch(syncManagerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,

      // ── RTL & Arabic Localization ──────────────────────────────
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
