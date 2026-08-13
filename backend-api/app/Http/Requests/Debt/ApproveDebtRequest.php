<?php

declare(strict_types=1);

namespace App\Http\Requests\Debt;

use Illuminate\Foundation\Http\FormRequest;

class ApproveDebtRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isMerchant() || $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            // Additional parameters if needed for approval
        ];
    }
}
