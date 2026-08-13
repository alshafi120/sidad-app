<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Payment;
use App\Models\User;

class PaymentPolicy
{
    public function before(User $user, string $ability): ?bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return null;
    }

    public function viewAny(User $user): bool
    {
        return $user->isMerchant();
    }

    public function view(User $user, Payment $payment): bool
    {
        $payment->loadMissing('debt');
        return $payment->debt && $payment->debt->merchant_id === $user->id;
    }
}
