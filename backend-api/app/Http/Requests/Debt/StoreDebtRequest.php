<?php

declare(strict_types=1);

namespace App\Http\Requests\Debt;

use Illuminate\Foundation\Http\FormRequest;

class StoreDebtRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isMerchant() || $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'customer_id'       => ['required', 'uuid', 'exists:customers,id'],
            'title'             => ['nullable', 'string', 'max:255'],
            'description'       => ['nullable', 'string', 'max:2000'],
            'total_amount'      => ['required_without:amount', 'nullable', 'integer', 'min:100'], 
            'amount'            => ['required_without:total_amount', 'nullable', 'numeric', 'min:1'],
            'installment_count' => ['nullable', 'integer', 'min:1', 'max:120'],
            'due_date'          => ['nullable', 'date', 'after_or_equal:today'],
        ];
    }
}
