<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                    => $this->id,
            'debt_id'               => $this->debt_id,
            'installment_id'        => $this->installment_id,
            'amount'                => $this->amount,
            'payment_method'        => $this->payment_method,
            'transaction_reference' => $this->transaction_reference,
            'status'                => $this->status,
            'notes'                 => $this->notes,
            'paid_at'               => $this->paid_at?->toISOString(),
            'created_at'            => $this->created_at?->toISOString(),
            
            // Optional loaded relations
            'debt'                  => new DebtResource($this->whenLoaded('debt')),
            'installment'           => new InstallmentResource($this->whenLoaded('installment')),
            'payer'                 => new UserResource($this->whenLoaded('payer')),
        ];
    }
}
