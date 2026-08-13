<?php

declare(strict_types=1);

namespace App\Services;

use App\Exceptions\BusinessException;
use App\Models\Customer;
use App\Models\User;
use App\Traits\LogsActivity;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class CustomerService
{
    use LogsActivity;
    /**
     * Get paginated, filtered, searchable customer list for a merchant.
     */
    public function list(User $merchant, array $filters = []): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        $allowedSortColumns = ['created_at', 'full_name', 'phone', 'is_active'];
        $sortBy = in_array($filters['sort_by'] ?? '', $allowedSortColumns) ? $filters['sort_by'] : 'created_at';
        
        $allowedSortDirs = ['asc', 'desc'];
        $sortDir = in_array(strtolower($filters['sort_dir'] ?? ''), $allowedSortDirs) ? strtolower($filters['sort_dir']) : 'desc';

        return Customer::query()
            ->forMerchant($merchant->id)
            ->withCount('debts')
            ->withSum('debts as total_debt', 'total_amount')
            ->withSum('debts as paid_amount', 'paid_amount')
            ->search($filters['search'] ?? null)
            ->active(isset($filters['is_active']) ? filter_var($filters['is_active'], FILTER_VALIDATE_BOOLEAN) : null)
            ->orderBy($sortBy, $sortDir)
            ->paginate($perPage);
    }

    /**
     * Get a single customer (merchant-scoped).
     */
    public function find(string $id, User $merchant): Customer
    {
        $customer = Customer::query()
            ->forMerchant($merchant->id)
            ->withCount('debts')
            ->withSum('debts as total_debt', 'total_amount')
            ->withSum('debts as paid_amount', 'paid_amount')
            ->find($id);

        if (! $customer) {
            throw new BusinessException('Customer not found.', 404);
        }

        return $customer;
    }

    /**
     * Create a new customer for a merchant.
     */
    public function create(User $merchant, array $data): Customer
    {
        return DB::transaction(function () use ($merchant, $data) {
            // Check duplicate phone for this merchant
            $exists = Customer::query()
                ->forMerchant($merchant->id)
                ->where('phone', $data['phone'])
                ->exists();

            if ($exists) {
                throw new BusinessException('A customer with this phone number already exists.', 422);
            }

            $customer = Customer::create([
                'merchant_id' => $merchant->id,
                'full_name' => $data['full_name'],
                'phone' => $data['phone'],
                'email' => $data['email'] ?? null,
                'national_id' => $data['national_id'] ?? null,
                'address' => $data['address'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            $this->logActivity($merchant, 'customer_created', [
                'customer_id' => $customer->id,
            ]);
            $this->forgetDashboardCache($merchant);

            return $customer;
        });
    }

    /**
     * Update an existing customer.
     */
    public function update(Customer $customer, array $data, User $merchant): Customer
    {
        return DB::transaction(function () use ($customer, $data, $merchant) {
            // Check duplicate phone if phone is being changed
            if (isset($data['phone']) && $data['phone'] !== $customer->phone) {
                $exists = Customer::query()
                    ->forMerchant($merchant->id)
                    ->where('phone', $data['phone'])
                    ->where('id', '!=', $customer->id)
                    ->exists();

                if ($exists) {
                    throw new BusinessException('A customer with this phone number already exists.', 422);
                }
            }

            $customer->update(array_filter([
                'full_name' => $data['full_name'] ?? null,
                'phone' => $data['phone'] ?? null,
                'email' => $data['email'] ?? null,
                'national_id' => $data['national_id'] ?? null,
                'address' => $data['address'] ?? null,
                'notes' => $data['notes'] ?? null,
                'is_active' => $data['is_active'] ?? null,
            ], fn ($value) => $value !== null));

            $this->logActivity($merchant, 'customer_updated', [
                'customer_id' => $customer->id,
            ]);
            $this->forgetDashboardCache($merchant);

            return $customer->fresh();
        });
    }

    /**
     * Soft-delete a customer.
     */
    public function delete(Customer $customer, User $merchant): void
    {
        $customer->delete();

        $this->logActivity($merchant, 'customer_deleted', [
            'customer_id' => $customer->id,
        ]);
        $this->forgetDashboardCache($merchant);
    }


}
