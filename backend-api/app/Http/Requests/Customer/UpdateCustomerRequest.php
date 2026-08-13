<?php

declare(strict_types=1);

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isMerchant() || $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'full_name'   => ['sometimes', 'string', 'max:255'],
            'phone'       => ['sometimes', 'string', 'max:20'],
            'email'       => ['nullable', 'email', 'max:255'],
            'national_id' => ['nullable', 'string', 'max:20'],
            'address'     => ['nullable', 'string', 'max:1000'],
            'notes'       => ['nullable', 'string', 'max:2000'],
            'is_active'   => ['sometimes', 'boolean'],
        ];
    }
}
