<?php

declare(strict_types=1);

namespace App\Enums;

enum DebtStatus: string
{
    case Pending       = 'pending';
    case Approved      = 'approved';
    case Active        = 'active';
    case PartiallyPaid = 'partially_paid';
    case Completed     = 'completed';
    case Rejected      = 'rejected';
    case Cancelled     = 'cancelled';
    case Overdue       = 'overdue';

    public function label(): string
    {
        return match ($this) {
            self::Pending       => 'Pending Approval',
            self::Approved      => 'Approved',
            self::Active        => 'Active',
            self::PartiallyPaid => 'Partially Paid',
            self::Completed     => 'Completed',
            self::Rejected      => 'Rejected',
            self::Cancelled     => 'Cancelled',
            self::Overdue       => 'Overdue',
        };
    }

    /**
     * Statuses that allow payment.
     */
    public static function payable(): array
    {
        return [self::Active, self::Approved, self::PartiallyPaid, self::Overdue];
    }
}
