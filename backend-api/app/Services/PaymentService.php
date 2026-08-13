<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\DebtStatus;
use App\Enums\InstallmentStatus;
use App\Enums\PaymentStatus;
use App\Exceptions\BusinessException;
use App\Models\Debt;
use App\Models\Installment;
use App\Models\Payment;
use App\Models\User;
use App\Traits\LogsActivity;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class PaymentService
{
    use LogsActivity;
    /**
     * Get paginated payment history for a merchant.
     */
    public function list(User $merchant, array $filters = []): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        $allowedSortColumns = ['created_at', 'amount', 'paid_at', 'status'];
        $sortBy = in_array($filters['sort_by'] ?? '', $allowedSortColumns) ? $filters['sort_by'] : 'created_at';
        
        $allowedSortDirs = ['asc', 'desc'];
        $sortDir = in_array(strtolower($filters['sort_dir'] ?? ''), $allowedSortDirs) ? strtolower($filters['sort_dir']) : 'desc';

        return Payment::query()
            ->with(['debt.customer', 'installment', 'payer'])
            ->whereHas('debt', function ($q) use ($merchant) {
                $q->where('merchant_id', $merchant->id);
            })
            ->when($filters['debt_id'] ?? null, fn ($q, $v) => $q->where('debt_id', $v))
            ->when($filters['installment_id'] ?? null, fn ($q, $v) => $q->where('installment_id', $v))
            ->orderBy($sortBy, $sortDir)
            ->paginate($perPage);
    }

    /**
     * Get a specific payment details.
     */
    public function find(string $id, User $merchant): Payment
    {
        $payment = Payment::query()
            ->with(['debt.customer', 'installment', 'payer'])
            ->whereHas('debt', function ($q) use ($merchant) {
                $q->where('merchant_id', $merchant->id);
            })
            ->find($id);

        if (! $payment) {
            throw new BusinessException('Payment not found.', 404);
        }

        return $payment;
    }

    /**
     * Get all payments for a specific installment.
     */
    public function getPaymentsForInstallment(string $installmentId, User $merchant)
    {
        $installment = Installment::query()
            ->with('debt')
            ->whereHas('debt', function ($q) use ($merchant) {
                $q->where('merchant_id', $merchant->id);
            })
            ->find($installmentId);

        if (! $installment) {
            throw new BusinessException('Installment not found.', 404);
        }

        return Payment::query()
            ->where('installment_id', $installmentId)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Get all payments for a specific debt.
     */
    public function getPaymentsForDebt(string $debtId, User $merchant)
    {
        $debt = Debt::query()
            ->forMerchant($merchant->id)
            ->find($debtId);

        if (! $debt) {
            throw new BusinessException('Debt not found.', 404);
        }

        return Payment::query()
            ->with(['installment', 'payer'])
            ->where('debt_id', $debtId)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Record a new payment against an installment.
     */
    public function recordPayment(User $merchant, array $data): Payment
    {
        return DB::transaction(function () use ($merchant, $data) {
            // 1. Validate installment exists and belongs to merchant.
            // If the client sends a debt_id, apply the payment to the first unpaid installment.
            $installmentQuery = Installment::query()
                ->with('debt')
                ->lockForUpdate();

            if (! empty($data['installment_id'])) {
                $installmentQuery->where('id', $data['installment_id']);
            } else {
                $installmentQuery
                    ->where('debt_id', $data['debt_id'])
                    ->whereColumn('paid_amount', '<', 'amount')
                    ->orderBy('installment_number');
            }

            $installment = $installmentQuery->first();

            if (! $installment || $installment->debt->merchant_id !== $merchant->id) {
                throw new BusinessException('Installment not found.', 404);
            }

            $debt = $installment->debt;

            // Check if debt is payable
            if (! in_array($debt->status, DebtStatus::payable(), true)) {
                throw new BusinessException('Payments cannot be made against this debt status.', 422);
            }

            // 2. Validate installment is unpaid
            if ($installment->status === InstallmentStatus::Paid) {
                throw new BusinessException('This installment is already fully paid.', 422);
            }

            // Validate payment amount does not exceed remaining installment amount
            $remainingInstallmentAmount = $installment->amount - $installment->paid_amount;
            if ($data['amount'] > $remainingInstallmentAmount) {
                throw new BusinessException('Payment amount cannot exceed the remaining installment amount.', 422);
            }

            // 3. Prevent duplicate transaction references (Already covered by DB unique constraint and FormRequest, but good to be safe)
            if (! empty($data['transaction_reference'])) {
                $exists = Payment::where('transaction_reference', $data['transaction_reference'])->exists();
                if ($exists) {
                    throw new BusinessException('A payment with this transaction reference already exists.', 422);
                }
            }

            // Lock the debt for update to safely adjust balances
            $debt = Debt::where('id', $debt->id)->lockForUpdate()->first();

            // 4. Create payment
            $payment = Payment::create([
                'debt_id' => $debt->id,
                'installment_id' => $installment->id,
                'paid_by' => $merchant->id, // Assuming merchant records the payment. If customer pays directly, this changes.
                'amount' => (int) $data['amount'],
                'payment_method' => $data['payment_method'] ?? 'cash',
                'transaction_reference' => $data['transaction_reference'] ?? null,
                'status' => PaymentStatus::Completed,
                'notes' => $data['notes'] ?? null,
                'paid_at' => now(),
            ]);

            // 5. Update installment status
            $installment->paid_amount += $payment->amount;
            if ($installment->paid_amount >= $installment->amount) {
                $installment->status = InstallmentStatus::Paid;
                $installment->paid_at = now();
            } else {
                $installment->status = InstallmentStatus::PartiallyPaid;
            }
            $installment->save();

            // 6. Update debt remaining_amount
            $debt->paid_amount += $payment->amount;
            $debt->remaining_amount -= $payment->amount;

            // 7. Auto-update debt status when fully paid
            if ($debt->remaining_amount <= 0) {
                $debt->status = DebtStatus::Completed;
            } elseif ($debt->status === DebtStatus::Approved || $debt->status === DebtStatus::Active) {
                $debt->status = DebtStatus::PartiallyPaid; // Using the new status
            }
            $debt->save();

            // 8. Create debt activity log
            $this->logActivity($merchant, 'payment_recorded', [
                'debt_id' => $debt->id,
                'installment_id' => $installment->id,
                'payment_id' => $payment->id,
                'amount' => $payment->amount,
            ]);
            $this->forgetDashboardCache($merchant);

            return $payment->load(['installment', 'debt']);
        });
    }


}
