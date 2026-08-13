<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\DebtStatus;
use App\Enums\InstallmentStatus;
use App\Exceptions\BusinessException;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Installment;
use App\Models\User;
use App\Traits\LogsActivity;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class DebtService
{
    use LogsActivity;
    /**
     * Get paginated debts for a merchant.
     */
    public function list(User $merchant, array $filters = []): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        $allowedSortColumns = ['created_at', 'total_amount', 'due_date', 'status'];
        $sortBy = in_array($filters['sort_by'] ?? '', $allowedSortColumns) ? $filters['sort_by'] : 'created_at';
        
        $allowedSortDirs = ['asc', 'desc'];
        $sortDir = in_array(strtolower($filters['sort_dir'] ?? ''), $allowedSortDirs) ? strtolower($filters['sort_dir']) : 'desc';

        return Debt::query()
            ->with(['customer'])
            ->forMerchant($merchant->id)
            ->when($filters['customer_id'] ?? null, fn ($q, $v) => $q->where('customer_id', $v))
            ->when($filters['status'] ?? null, fn ($q, $v) => $q->where('status', $v))
            ->orderBy($sortBy, $sortDir)
            ->paginate($perPage);
    }

    /**
     * Get a single debt with its installments.
     */
    public function find(string $id, User $merchant): Debt
    {
        $debt = Debt::query()
            ->with(['customer', 'installments' => fn ($q) => $q->orderBy('installment_number')])
            ->forMerchant($merchant->id)
            ->find($id);

        if (! $debt) {
            throw new BusinessException('Debt not found.', 404);
        }

        return $debt;
    }

    /**
     * Create a new debt and generate its installments.
     */
    public function create(User $merchant, array $data): Debt
    {
        // Validate customer belongs to merchant
        $customer = Customer::query()
            ->forMerchant($merchant->id)
            ->find($data['customer_id']);

        if (! $customer) {
            throw new BusinessException('Customer not found or does not belong to this merchant.', 422);
        }

        $title = $data['title'] ?? ($data['description'] ?? 'مديونية جديدة');
        $installmentCount = (int) ($data['installment_count'] ?? 1);
        $totalAmount = isset($data['total_amount'])
            ? (int) $data['total_amount']
            : (int) round(($data['amount'] ?? 0) * 100);

        return DB::transaction(function () use ($merchant, $data, $title, $installmentCount, $totalAmount) {
            $debt = Debt::create([
                'merchant_id' => $merchant->id,
                'customer_id' => $data['customer_id'],
                'title' => $title,
                'description' => $data['description'] ?? null,
                'total_amount' => $totalAmount,
                'paid_amount' => 0,
                'remaining_amount' => $totalAmount,
                'currency' => 'SAR',
                'status' => DebtStatus::Pending,
                'installment_count' => $installmentCount,
                'due_date' => $data['due_date'] ?? null,
            ]);

            $this->generateInstallments($debt);

            $this->logActivity($merchant, 'debt_created', ['debt_id' => $debt->id]);
            $this->forgetDashboardCache($merchant);

            return $debt->load('installments');
        });
    }

    /**
     * Approve a pending debt.
     */
    public function approve(Debt $debt, User $merchant): Debt
    {
        if ($debt->status !== DebtStatus::Pending) {
            throw new BusinessException('Only pending debts can be approved.', 422);
        }

        DB::transaction(function () use ($debt, $merchant) {
            $debt->update([
                'status' => DebtStatus::Approved,
                'approved_at' => now(),
                'approved_by' => $merchant->id,
            ]);

            $this->logActivity($merchant, 'debt_approved', ['debt_id' => $debt->id]);
            $this->forgetDashboardCache($merchant);
        });

        return $debt->fresh();
    }

    /**
     * Reject a pending debt.
     */
    public function reject(Debt $debt, string $reason, User $merchant): Debt
    {
        if ($debt->status !== DebtStatus::Pending) {
            throw new BusinessException('Only pending debts can be rejected.', 422);
        }

        DB::transaction(function () use ($debt, $reason, $merchant) {
            $debt->update([
                'status' => DebtStatus::Rejected,
                'rejection_reason' => $reason,
            ]);

            $this->logActivity($merchant, 'debt_rejected', [
                'debt_id' => $debt->id,
                'reason' => $reason,
            ]);
            $this->forgetDashboardCache($merchant);
        });

        return $debt->fresh();
    }

    /**
     * Automatically generate installments for a debt.
     */
    private function generateInstallments(Debt $debt): void
    {
        $baseAmount = (int) floor($debt->total_amount / $debt->installment_count);
        $remainder = $debt->total_amount % $debt->installment_count;

        // Base due date
        $dueDate = $debt->due_date ? Carbon::parse($debt->due_date) : now()->addMonth();

        for ($i = 1; $i <= $debt->installment_count; $i++) {
            // Add remainder to the first installment
            $amount = ($i === 1) ? $baseAmount + $remainder : $baseAmount;

            Installment::create([
                'debt_id' => $debt->id,
                'installment_number' => $i,
                'amount' => $amount,
                'paid_amount' => 0,
                'status' => InstallmentStatus::Upcoming,
                'due_date' => $dueDate->copy()->addMonths($i - 1),
            ]);
        }
    }


}
