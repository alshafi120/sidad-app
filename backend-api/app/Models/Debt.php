<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\DebtStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Debt extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'merchant_id',
        'customer_id',
        'title',
        'description',
        'total_amount',
        'paid_amount',
        'remaining_amount',
        'currency',
        'status',
        'installment_count',
        'due_date',
        'approved_at',
        'approved_by',
        'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'status' => DebtStatus::class,
            'due_date' => 'date',
            'approved_at' => 'datetime',
        ];
    }

    // ─── Relationships ────────────────────────────────────────

    public function merchant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function installments(): HasMany
    {
        return $this->hasMany(Installment::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopeForMerchant(Builder $query, string $merchantId): Builder
    {
        return $query->where('merchant_id', $merchantId);
    }

    public function scopeForCustomer(Builder $query, string $customerId): Builder
    {
        return $query->where('customer_id', $customerId);
    }
}
