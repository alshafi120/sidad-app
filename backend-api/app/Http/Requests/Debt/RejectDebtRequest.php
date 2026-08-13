<?php

declare(strict_types=1);

namespace App\Http\Requests\Debt;

use Illuminate\Foundation\Http\FormRequest;

class RejectDebtRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isMerchant() || $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'rejection_reason' => ['required', 'string', 'max:2000'],
        ];
    }
}
