/// Register Payment screen matching Stitch "تسجيل سداد - سداد" design with premium animations.
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
import '../../../debts/presentation/providers/debt_providers.dart';
import '../providers/payment_providers.dart';

class RegisterPaymentScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? debtId;
  const RegisterPaymentScreen({super.key, this.customerId, this.debtId});

  @override
  ConsumerState<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends ConsumerState<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _selectedCustomerId;
  String? _selectedDebtId;
  DateTime? _paymentDate;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    _selectedDebtId = widget.debtId;
    _paymentDate = DateTime.now();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDebtId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الدين المراد تسديده')),
      );
      return;
    }

    ref.read(paymentControllerProvider.notifier).recordPayment(
          debtId: _selectedDebtId!,
          amount: double.parse(_amount.text),
          notes: _notes.text.isNotEmpty ? _notes.text : null,
          receiptNumber: null, // Optional
        );
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final paymentState = ref.watch(paymentControllerProvider);

    ref.listen<AsyncValue<void>>(paymentControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      } else if (next is AsyncData && prev is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل السداد بنجاح!')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/merchant-dashboard');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل سداد')),
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
                Text('العميل', style: Theme.of(context).textTheme.labelLarge)
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: customersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('خطأ: $err', style: const TextStyle(color: AppColors.error)),
                    ),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      ),
                      hint: const Text('اختر العميل', style: TextStyle(color: Colors.grey)),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: widget.customerId != null && widget.debtId != null
                          ? null // Locked if coming from specific debt
                          : (v) {
                              setState(() {
                                _selectedCustomerId = v;
                                _selectedDebtId = null; // reset debt when customer changes
                              });
                            },
                      validator: (v) => v == null ? 'الرجاء اختيار العميل' : null,
                    ),
                  ),
                ).animate(delay: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // Debt picker
                if (_selectedCustomerId != null) ...[
                  Text('الدين المراد سداده', style: Theme.of(context).textTheme.labelLarge)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final debtsAsync = ref.watch(customerDebtsProvider(_selectedCustomerId!));
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: debtsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('خطأ: $err', style: const TextStyle(color: AppColors.error)),
                          ),
                          data: (debts) {
                            final pendingDebts = debts.where((d) => !d.isPaid).toList();
                            if (pendingDebts.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('لا توجد ديون غير مسددة لهذا العميل.'),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedDebtId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              ),
                              hint: const Text('اختر الدين', style: TextStyle(color: Colors.grey)),
                              isExpanded: true,
                              items: pendingDebts.map((d) {
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text('${d.description ?? 'دين'} - المتبقي: ${d.remaining} ${AppStrings.currency}'),
                                );
                              }).toList(),
                              onChanged: widget.debtId != null
                                  ? null // Locked if coming from specific debt
                                  : (v) => setState(() => _selectedDebtId = v),
                              validator: (v) => v == null ? 'الرجاء اختيار الدين' : null,
                            );
                          },
                        ),
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                SidadTextField(
                  label: 'المبلغ المسدد',
                  hint: '0.00',
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  textDirection: ui.TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 18),
                    child: Text(AppStrings.currency, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال المبلغ' : null,
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                
                // Payment date
                Text('تاريخ السداد', style: Theme.of(context).textTheme.labelLarge).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _paymentDate = d);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          _paymentDate != null ? DateFormat('dd MMMM yyyy', 'ar').format(_paymentDate!) : 'اختر تاريخ السداد',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                SidadTextField(
                  label: 'ملاحظات (اختياري)',
                  hint: 'أي ملاحظات حول السداد',
                  controller: _notes,
                  maxLines: 3,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),
                SidadButton(
                  text: 'تأكيد السداد',
                  isLoading: paymentState.isLoading,
                  onPressed: paymentState.isLoading ? null : _save,
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

