import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' if (dart.library.js_interop) 'dart:html' as universal_io;
import '../../features/debts/domain/entities/debt_entity.dart';
import '../../features/customer/domain/entities/customer_entity.dart';

class ExportService {
  /// Generates a structured CSV file representing the customer's debt statement
  /// and opens the native sharing dialog to export it to Excel/WhatsApp/Email.
  static Future<void> exportCustomerDebtsToExcel({
    required Customer customer,
    required List<Debt> debts,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');
    final numberFormat = NumberFormat('#,###', 'ar');

    final buffer = StringBuffer();
    // Add UTF-8 BOM (Byte Order Mark) so Excel opens it with Arabic text correctly encoded
    buffer.write('\uFEFF');

    // Report Header
    buffer.writeln('كشف حساب العميل: ${customer.name}');
    buffer.writeln('رقم الهاتف: ${customer.phone}');
    buffer.writeln('تاريخ التصدير: ${dateFormat.format(DateTime.now())}');
    buffer.writeln(
      'إجمالي المديونية: ${numberFormat.format(customer.totalDebt)} ر.ي',
    );
    buffer.writeln(
      'المبلغ المسدد: ${numberFormat.format(customer.paidAmount)} ر.ي',
    );
    buffer.writeln(
      'المبلغ المتبقي: ${numberFormat.format(customer.remainingDebt)} ر.ي',
    );
    buffer.writeln();

    // Column Headers
    buffer.writeln(
      'رقم العملية,الوصف,المبلغ الكلي,المبلغ المسدد,المبلغ المتبقي,الحالة,تاريخ الإنشاء,تاريخ الاستحقاق',
    );

    for (int i = 0; i < debts.length; i++) {
      final debt = debts[i];
      final remaining = debt.amount - debt.paidAmount;
      final statusStr = _getStatusText(debt.status);
      final createdStr = dateFormat.format(debt.createdAt);
      final dueStr = debt.dueDate != null
          ? dateFormat.format(debt.dueDate!)
          : '-';

      // Sanitize description to prevent CSV breaking
      final desc = (debt.description ?? 'مديونية')
          .replaceAll(',', ' ')
          .replaceAll('\n', ' ');

      buffer.writeln(
        '${i + 1},'
        '$desc,'
        '${debt.amount},'
        '${debt.paidAmount},'
        '$remaining,'
        '$statusStr,'
        '$createdStr,'
        '$dueStr',
      );
    }

    if (kIsWeb) {
      // On web, share text statement directly for maximum compatibility
      await shareTextStatement(customer: customer, debts: debts);
      return;
    }

    try {
      // Save file locally to temporary storage
      final tempDir = await getTemporaryDirectory();
      final sanitizedCustomerName = customer.name
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
          .replaceAll(' ', '_');
      final filePath = '${tempDir.path}/كشف_حساب_$sanitizedCustomerName.csv';
      final file = universal_io.File(filePath);
      await file.writeAsString(
        buffer.toString(),
        mode: universal_io.FileMode.write,
        encoding: utf8,
      );

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'text/csv')],
        subject: 'كشف حساب - ${customer.name}',
        text:
            'مرفق كشف حساب العميل ${customer.name} - إجمالي الديون المتبقية: ${numberFormat.format(customer.remainingDebt)} ر.ي\nتم التصدير عبر منصة سداد.',
      );
    } catch (_) {
      await shareTextStatement(customer: customer, debts: debts);
    }
  }

  /// Generates a beautiful formatted text receipt/statement that can be shared directly via WhatsApp / SMS.
  static Future<void> shareTextStatement({
    required Customer customer,
    required List<Debt> debts,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
    final numberFormat = NumberFormat('#,###', 'ar');

    final buffer = StringBuffer();
    buffer.writeln('📄 *كشف حساب مديونية - تطبيق سداد*');
    buffer.writeln('══════════════════════');
    buffer.writeln('👤 *العميل:* ${customer.name}');
    buffer.writeln('📞 *الهاتف:* ${customer.phone}');
    buffer.writeln('📅 *التاريخ:* ${dateFormat.format(DateTime.now())}');
    buffer.writeln('══════════════════════');
    buffer.writeln(
      '💰 *إجمالي المديونية:* ${numberFormat.format(customer.totalDebt)} ر.ي',
    );
    buffer.writeln(
      '✅ *المبلغ المسدد:* ${numberFormat.format(customer.paidAmount)} ر.ي',
    );
    buffer.writeln(
      '⚠️ *المبلغ المتبقي:* ${numberFormat.format(customer.remainingDebt)} ر.ي',
    );
    buffer.writeln('══════════════════════');
    buffer.writeln('📋 *تفاصيل العمليات:*');

    if (debts.isEmpty) {
      buffer.writeln('لا توجد عمليات مسجلة حالياً.');
    } else {
      for (int i = 0; i < debts.length; i++) {
        final debt = debts[i];
        final statusStr = _getStatusText(debt.status);
        final remaining = debt.amount - debt.paidAmount;
        buffer.writeln('${i + 1}️⃣ *${debt.description ?? 'مديونية'}*');
        buffer.writeln(
          '   • الإجمالي: ${numberFormat.format(debt.amount)} ر.ي',
        );
        buffer.writeln(
          '   • المسدد: ${numberFormat.format(debt.paidAmount)} ر.ي | المتبقي: ${numberFormat.format(remaining)} ر.ي',
        );
        buffer.writeln(
          '   • الحالة: $statusStr',
        );
        buffer.writeln(
          '   • التاريخ: ${dateFormat.format(debt.createdAt)}',
        );
        if (i < debts.length - 1) {
          buffer.writeln('──────────────────────');
        }
      }
    }

    buffer.writeln('\n🙏 *شكراً لتعاملكم معنا ونرجو المبادرة بالسداد.*');
    buffer.writeln('تم التوليد تلقائياً عبر منصة سداد الإلكترونية.');

    await Share.share(
      buffer.toString(),
      subject: 'كشف حساب - ${customer.name}',
    );
  }

  static String _getStatusText(DebtStatusEnum status) {
    return switch (status) {
      DebtStatusEnum.paid => 'مسدد بالكامل ✅',
      DebtStatusEnum.overdue => 'متأخر عن السداد ⚠️',
      DebtStatusEnum.partiallyPaid => 'مسدد جزئياً 🔄',
      _ => 'معلق ⏳',
    };
  }
}
