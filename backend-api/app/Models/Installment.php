<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\InstallmentStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Installment extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'debt_id',
        'installment_number',
        'amount',
        'paid_amount',
        'status',
        'due_date',
        'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => InstallmentStatus::class,
            'due_date' => 'date',
            'paid_at' => 'datetime',
        ];
    }

    // ─── Relationships ────────────────────────────────────────

    public function debt(): BelongsTo
    {
        return $this->belongsTo(Debt::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
