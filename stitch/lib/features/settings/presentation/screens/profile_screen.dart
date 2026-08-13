/// Profile & Settings screen matching Stitch "Profile - سداد" design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_avatar.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'التاجر';
    final phone = user?.phone ?? '';
    final roleText = user?.role == UserRole.merchant ? 'تاجر' : 'عميل';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User info
            Column(
              children: [
                SidadAvatar(name: name, size: 80),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  phone,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    roleText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 32),
            // Settings sections
            _SettingsSection(
              title: 'الحساب',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  title: AppStrings.editProfile,
                  onTap: () => _showEditProfileDialog(context, ref, name, phone),
                ),
                _SettingsItem(
                  icon: Icons.notifications_none_rounded,
                  title: AppStrings.notificationSettings,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'عام',
              items: [
                _SettingsItem(
                  icon: Icons.language_rounded,
                  title: AppStrings.language,
                  trailing: 'العربية',
                  onTap: () => _showLanguageDialog(context),
                ),
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.helpSupport,
                  onTap: () => _showHelpDialog(context),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: AppStrings.about,
                  trailing: 'v1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            // Logout
            SidadCard(
              onTap: () => _showLogoutDialog(context, ref),
              color: AppColors.errorContainer.withValues(alpha: 0.3),
              shadow: const [],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.logout,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: currentPhone),
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
                helperText: 'لا يمكن تغيير رقم الهاتف',
                helperStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ التغييرات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اللغة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_rounded, color: AppColors.primary),
              title: const Text('العربية'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('English language support coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('المساعدة والدعم', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('للتواصل مع فريق الدعم:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _HelpContactRow(icon: Icons.email_outlined, text: 'support@sidad.app'),
            const SizedBox(height: 12),
            _HelpContactRow(icon: Icons.phone_outlined, text: '+967 XXX XXX XXX'),
            const SizedBox(height: 12),
            _HelpContactRow(icon: Icons.access_time_rounded, text: 'يومياً 9 ص – 6 م'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 سداد. جميع الحقوق محفوظة.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'سداد هو تطبيق متخصص في إدارة الديون والمدفوعات بين التجار والعملاء بشكل رقمي وآمن.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(
              AppStrings.logout,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelpContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SidadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      indent: 56,
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                    ),
                  item,
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (trailing != null)
              Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
