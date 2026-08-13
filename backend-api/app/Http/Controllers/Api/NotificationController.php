<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get recent notifications derived from activity logs.
     *
     * GET /api/notifications
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $actions = [
            'customer_created',
            'debt_created',
            'debt_approved',
            'debt_rejected',
            'payment_recorded'
        ];

        // Fetch logs
        $activities = ActivityLog::where('user_id', $user->id)
            ->whereIn('action', $actions)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        // Gather IDs to query in batch
        $customerIds = [];
        $debtIds = [];
        $paymentIds = [];

        foreach ($activities as $act) {
            $meta = $act->metadata ?? [];
            if (isset($meta['customer_id'])) {
                $customerIds[] = $meta['customer_id'];
            }
            if (isset($meta['debt_id'])) {
                $debtIds[] = $meta['debt_id'];
            }
            if (isset($meta['payment_id'])) {
                $paymentIds[] = $meta['payment_id'];
            }
        }

        // Run batch queries (exactly 3 queries max, fully avoiding N+1)
        $customers = Customer::whereIn('id', array_unique($customerIds))->get()->keyBy('id');
        $debts = Debt::with('customer')->whereIn('id', array_unique($debtIds))->get()->keyBy('id');
        $payments = Payment::whereIn('id', array_unique($paymentIds))->get()->keyBy('id');

        // Map activities to notifications
        $notifications = $activities->map(function ($act) use ($customers, $debts, $payments) {
            $meta = $act->metadata ?? [];
            $title = 'تنبيه جديد';
            $body = 'نشاط غير معروف';
            $icon = 'notifications';
            $color = 'info';

            switch ($act->action) {
                case 'customer_created':
                    $custName = $customers[$meta['customer_id']]->full_name ?? 'عميل غير معروف';
                    $title = 'عميل جديد';
                    $body = "تمت إضافة العميل {$custName} بنجاح";
                    $icon = 'person_add';
                    $color = 'info';
                    break;
                case 'debt_created':
                    $debt = $debts[$meta['debt_id']] ?? null;
                    $custName = $debt->customer->full_name ?? 'غير معروف';
                    $amount = number_format(($debt->total_amount ?? 0) / 100, 2);
                    $title = 'مديونية جديدة';
                    $body = "تم تسجيل مديونية بقيمة {$amount} ر.س لـ {$custName}";
                    $icon = 'receipt_long';
                    $color = 'primary';
                    break;
                case 'debt_approved':
                    $debt = $debts[$meta['debt_id']] ?? null;
                    $custName = $debt->customer->full_name ?? 'غير معروف';
                    $amount = number_format(($debt->total_amount ?? 0) / 100, 2);
                    $title = 'تمت الموافقة على المديونية';
                    $body = "تمت الموافقة على مديونية بقيمة {$amount} ر.س لـ {$custName}";
                    $icon = 'check_circle';
                    $color = 'success';
                    break;
                case 'debt_rejected':
                    $debt = $debts[$meta['debt_id']] ?? null;
                    $custName = $debt->customer->full_name ?? 'غير معروف';
                    $amount = number_format(($debt->total_amount ?? 0) / 100, 2);
                    $reason = $meta['reason'] ?? 'بدون سبب';
                    $title = 'تم رفض المديونية';
                    $body = "تم رفض مديونية بقيمة {$amount} ر.س لـ {$custName}. السبب: {$reason}";
                    $icon = 'cancel';
                    $color = 'error';
                    break;
                case 'payment_recorded':
                    $payment = $payments[$meta['payment_id']] ?? null;
                    $debt = $debts[$meta['debt_id']] ?? ($payment ? $payment->debt : null);
                    $custName = $debt->customer->full_name ?? 'غير معروف';
                    $amount = number_format(($meta['amount'] ?? 0) / 100, 2);
                    $title = 'تم السداد';
                    $body = "قام {$custName} بسداد مبلغ {$amount} ر.س";
                    $icon = 'check_circle';
                    $color = 'success';
                    break;
            }

            return [
                'id'         => $act->id,
                'title'      => $title,
                'body'       => $body,
                'created_at' => $act->created_at->toISOString(),
                'icon'       => $icon,
                'color'      => $color,
                'action'     => $act->action,
                'metadata'   => $act->metadata,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Notifications retrieved successfully.',
            'data'    => $notifications,
        ]);
    }
}
