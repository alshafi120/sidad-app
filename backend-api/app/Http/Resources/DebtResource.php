<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DebtResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                => $this->id,
            'merchant_id'       => $this->merchant_id,
            'customer_id'       => $this->customer_id,
            'title'             => $this->title,
            'description'       => $this->description,
            'total_amount'      => (double) ($this->total_amount / 100.0),
            'paid_amount'       => (double) ($this->paid_amount / 100.0),
            'remaining_amount'  => (double) ($this->remaining_amount / 100.0),
            'currency'          => $this->currency,
            'status'            => $this->status,
            'installment_count' => $this->installment_count,
            'due_date'          => $this->due_date?->toISOString(),
            'approved_at'       => $this->approved_at?->toISOString(),
            'rejection_reason'  => $this->rejection_reason,
            'created_at'        => $this->created_at?->toISOString(),
            'updated_at'        => $this->updated_at?->toISOString(),
            // Optional loaded relations
            'customer'          => new CustomerResource($this->whenLoaded('customer')),
            'installments'      => InstallmentResource::collection($this->whenLoaded('installments')),
        ];
    }
}
