<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Customer;
use App\Models\User;

class CustomerPolicy
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
     * Merchant can view their own customers list.
     */
    public function viewAny(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Merchant can view their own customer.
     */
    public function view(User $user, Customer $customer): bool
    {
        return $user->id === $customer->merchant_id;
    }

    /**
     * Merchant can create customers.
     */
    public function create(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Merchant can update their own customer.
     */
    public function update(User $user, Customer $customer): bool
    {
        return $user->id === $customer->merchant_id;
    }

    /**
     * Merchant can delete their own customer.
     */
    public function delete(User $user, Customer $customer): bool
    {
        return $user->id === $customer->merchant_id;
    }
}
