<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Debt;
use App\Models\User;

class DebtPolicy
{
    /**
     * Admin can do anything.
     */
    public function before(User $user, string $ability): ?bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return null;
    }

    /**
     * Merchant can view their own debts list.
     */
    public function viewAny(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Merchant can view their own debt.
     */
    public function view(User $user, Debt $debt): bool
    {
        return $user->id === $debt->merchant_id;
    }

    /**
     * Merchant can create debts.
     */
    public function create(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Merchant can update their own debt.
     */
    public function update(User $user, Debt $debt): bool
    {
        return $user->id === $debt->merchant_id;
    }

    /**
     * Merchant can delete their own debt.
     */
    public function delete(User $user, Debt $debt): bool
    {
        return $user->id === $debt->merchant_id;
    }

    /**
     * Merchant can approve their own debt.
     */
    public function approve(User $user, Debt $debt): bool
    {
        return $user->id === $debt->merchant_id;
    }

    /**
     * Merchant can reject their own debt.
     */
    public function reject(User $user, Debt $debt): bool
    {
        return $user->id === $debt->merchant_id;
    }
}
