<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'debt_id',
        'installment_id',
        'paid_by',
        'amount',
        'payment_method',
        'transaction_reference',
        'status',
        'metadata',
        'notes',
        'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => PaymentStatus::class,
            'metadata' => 'array',
            'paid_at' => 'datetime',
        ];
    }

    // ─── Relationships ────────────────────────────────────────

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }

    public function installment(): BelongsTo
    {
        return $this->belongsTo(Installment::class);
    }

    public function payer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'paid_by');
    }
}
