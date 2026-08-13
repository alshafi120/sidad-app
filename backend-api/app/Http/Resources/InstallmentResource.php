<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InstallmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                 => $this->id,
            'debt_id'            => $this->debt_id,
            'installment_number' => $this->installment_number,
            'amount'             => $this->amount,
            'paid_amount'        => $this->paid_amount,
            'status'             => $this->status,
            'due_date'           => $this->due_date?->toISOString(),
            'paid_at'            => $this->paid_at?->toISOString(),
        ];
    }
}
