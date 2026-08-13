<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'merchant_id',
        'full_name',
        'phone',
        'email',
        'national_id',
        'address',
        'notes',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    // ─── Relationships ────────────────────────────────────────

    public function debts(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Debt::class);
    }

    public function merchant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    // ─── Scopes ───────────────────────────────────────────────

    /**
     * Scope to merchant's own customers.
     */
    public function scopeForMerchant(Builder $query, string $merchantId): Builder
    {
        return $query->where('merchant_id', $merchantId);
    }

    /**
     * Search by name, phone, email, or national_id.
     */
    public function scopeSearch(Builder $query, ?string $term): Builder
    {
        if (empty($term)) {
            return $query;
        }

        // Escape wildcards to prevent SQL Injection
        $escapedTerm = str_replace(['\\', '%', '_'], ['\\\\', '\%', '\_'], $term);

        return $query->where(function (Builder $q) use ($escapedTerm) {
            $q->where('full_name', 'like', "%{$escapedTerm}%")
              ->orWhere('phone', 'like', "%{$escapedTerm}%")
              ->orWhere('email', 'like', "%{$escapedTerm}%")
              ->orWhere('national_id', 'like', "%{$escapedTerm}%");
        });
    }

    /**
     * Filter by active status.
     */
    public function scopeActive(Builder $query, ?bool $active): Builder
    {
        if ($active === null) {
            return $query;
        }

        return $query->where('is_active', $active);
    }
}
