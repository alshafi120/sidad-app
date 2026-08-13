/// Add Customer screen matching Stitch "إضافة عميل جديد - سداد" design with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../../../../shared/widgets/sidad_text_field.dart';
import '../providers/customer_providers.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});
  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _notesFocusNode.addListener(() => setState(() {}));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref
        .read(customerControllerProvider.notifier)
        .createCustomer(
          name: _name.text,
          phone: _phone.text,
          notes: _notes.text.isNotEmpty ? _notes.text : null,
        );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerControllerProvider);

    ref.listen<AsyncValue<void>>(customerControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (next is AsyncData && prev is AsyncLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/merchant-dashboard');
        }
      }
    });

    var animDelay = 0.ms;
    Widget animateWidget(Widget child) {
      final currentDelay = animDelay;
      animDelay += 80.ms;
      return child
          .animate(delay: currentDelay)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutQuad,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addCustomer),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.pageHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Name field
                animateWidget(
                  SidadTextField(
                    label: AppStrings.customerName,
                    hint: 'مثال: محمد أحمد',
                    controller: _name,
                    focusNode: _nameFocusNode,
                    prefixIcon: AnimatedScale(
                      scale: _nameFocusNode.hasFocus ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: _nameFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'الرجاء إدخال اسم العميل'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Phone field
                animateWidget(
                  SidadTextField(
                    label: AppStrings.customerPhone,
                    hint: '7XXXXXXXX',
                    controller: _phone,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixIcon: AnimatedScale(
                      scale: _phoneFocusNode.hasFocus ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: _phoneFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                    validator: (v) => v == null || v.length < 9
                        ? 'الرجاء إدخال رقم جوال صحيح'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Notes field
                animateWidget(
                  SidadTextField(
                    label: AppStrings.customerNotes,
                    hint: 'ملاحظات إضافية (اختياري)',
                    controller: _notes,
                    focusNode: _notesFocusNode,
                    maxLines: 3,
                    prefixIcon: AnimatedScale(
                      scale: _notesFocusNode.hasFocus ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.notes_rounded,
                        color: _notesFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Save button
                animateWidget(
                  SidadButton(
                    text: AppStrings.saveCustomer,
                    isLoading: customerState.isLoading,
                    onPressed: customerState.isLoading ? null : _save,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
