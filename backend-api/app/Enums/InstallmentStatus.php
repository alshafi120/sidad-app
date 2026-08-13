<?php

declare(strict_types=1);

namespace App\Enums;

enum InstallmentStatus: string
{
    case Upcoming      = 'upcoming';
    case Due           = 'due';
    case Paid          = 'paid';
    case Overdue       = 'overdue';
    case PartiallyPaid = 'partially_paid';

    public function label(): string
    {
        return match ($this) {
            self::Upcoming      => 'Upcoming',
            self::Due           => 'Due',
            self::Paid          => 'Paid',
            self::Overdue       => 'Overdue',
            self::PartiallyPaid => 'Partially Paid',
        };
    }
}
