/// Add Debt screen matching Stitch "Add Debt - سداد" design with robust state management.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../../../../shared/widgets/sidad_text_field.dart';
import '../../../customer/presentation/providers/customer_providers.dart';
import '../../../merchant/presentation/providers/dashboard_provider.dart';
import '../providers/debt_providers.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final String? prefilledCustomerId;
  const AddDebtScreen({super.key, this.prefilledCustomerId});
  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  final _notes = TextEditingController();
  String? _selectedCustomer;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    // Pre-select customer if provided from navigation extra
    _selectedCustomer = widget.prefilledCustomerId;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref
        .read(debtControllerProvider.notifier)
        .createDebt(
          customerId: _selectedCustomer!,
          amount: double.parse(_amount.text),
          description: _desc.text.isNotEmpty ? _desc.text : null,
          dueDate: _dueDate != null
              ? DateFormat('yyyy-MM-dd').format(_dueDate!)
              : null,
        );
  }

  @override
  void dispose() {
    _amount.dispose();
    _desc.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final debtState = ref.watch(debtControllerProvider);

    ref.listen<AsyncValue<void>>(debtControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (next is AsyncData && prev is AsyncLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
        // Invalidate dashboard so it fetches updated numbers
        ref.invalidate(dashboardProvider);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/merchant-dashboard');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addDebt)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.pageHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Customer picker
                Text('اختر العميل', style: Theme.of(context).textTheme.labelLarge).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: customersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'خطأ في تحميل العملاء: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _selectedCustomer,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                      ),
                      hint: const Text('أحمد علي', style: TextStyle(color: Colors.grey)),
                      items: customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                      validator: (v) =>
                          v == null ? 'الرجاء اختيار العميل' : null,
                    ),
                  ),
                ).animate(delay: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                SidadTextField(
                  label: AppStrings.debtAmount,
                  hint: '0.00',
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  textDirection: ui.TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 18),
                    child: Text(
                      AppStrings.currency,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'الرجاء إدخال المبلغ' : null,
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                SidadTextField(
                  label: 'وصف الدين (اختياري)',
                  hint: 'مثال: بضاعة / خدمات / أخرى',
                  controller: _desc,
                  maxLines: 1,
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                // Due date
                Text(
                  'تاريخ الدين',
                  style: Theme.of(context).textTheme.labelLarge,
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _dueDate = d);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dueDate != null
                              ? DateFormat('dd MMMM yyyy', 'ar').format(_dueDate!)
                              : DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                SidadTextField(
                  label: 'ملاحظات (اختياري)',
                  hint: 'أي ملاحظات إضافية',
                  controller: _notes,
                  maxLines: 3,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),
                SidadButton(
                  text: 'حفظ الدين',
                  isLoading: debtState.isLoading,
                  onPressed: debtState.isLoading ? null : _save,
                  icon: null,
                ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

