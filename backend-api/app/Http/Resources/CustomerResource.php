<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CustomerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'merchant_id' => $this->merchant_id,
            'full_name'   => $this->full_name,
            'phone'       => $this->phone,
            'email'       => $this->email,
            'national_id' => $this->national_id,
            'address'     => $this->address,
            'notes'       => $this->notes,
            'is_active'   => $this->is_active,
            'total_debt'  => (double) (($this->total_debt ?? 0) / 100),
            'paid_amount' => (double) (($this->paid_amount ?? 0) / 100),
            'debt_count'  => (int) ($this->debts_count ?? 0),
            'created_at'  => $this->created_at?->toISOString(),
            'updated_at'  => $this->updated_at?->toISOString(),
        ];
    }
}
