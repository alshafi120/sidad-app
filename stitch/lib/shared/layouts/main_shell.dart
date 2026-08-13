/// Bottom navigation shell for merchant/customer roles.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppColors.primaryFixed.withValues(alpha: 0.3),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  selectedIcon: Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(
                    Icons.people_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'العملاء',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  selectedIcon: Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'الإشعارات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
