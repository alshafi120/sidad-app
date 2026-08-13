/// Status chip with full rounding per Stitch design (9999px radius).
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum DebtStatus { paid, pending, overdue }

class StatusChip extends StatelessWidget {
  final DebtStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _color => switch (status) {
    DebtStatus.paid => AppColors.success,
    DebtStatus.pending => AppColors.warning,
    DebtStatus.overdue => AppColors.error,
  };

  String get _label => switch (status) {
    DebtStatus.paid => 'مسدّدة',
    DebtStatus.pending => 'معلّقة',
    DebtStatus.overdue => 'متأخرة',
  };
}
