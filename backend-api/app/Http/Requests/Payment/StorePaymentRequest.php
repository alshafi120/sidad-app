<?php

declare(strict_types=1);

namespace App\Http\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;

class StorePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->isMerchant() || $this->user()->isAdmin();
    }

    public function rules(): array
    {
        return [
            'installment_id' => ['required_without:debt_id', 'uuid', 'exists:installments,id'],
            'debt_id' => ['required_without:installment_id', 'uuid', 'exists:debts,id'],
            'amount' => ['required', 'integer', 'min:1'], // in cents
            'payment_method' => ['sometimes', 'string', 'max:50'],
            'transaction_reference' => ['nullable', 'string', 'max:100', 'unique:payments,transaction_reference'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'amount.min' => 'Payment amount must be greater than zero.',
            'transaction_reference.unique' => 'A payment with this transaction reference already exists.',
        ];
    }
}
