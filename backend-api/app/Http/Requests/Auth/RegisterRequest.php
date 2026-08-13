<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'full_name' => ['required', 'string', 'max:255'],
            'phone'     => ['required', 'string', 'max:20', 'unique:users,phone'],
            'email'     => ['required', 'email', 'max:255', 'unique:users,email'],
            'password'  => ['required', 'string', 'min:8', 'confirmed', 'regex:/[a-z]/', 'regex:/[A-Z]/', 'regex:/[0-9]/'],
        ];
    }

    public function messages(): array
    {
        return [
            'phone.unique'    => 'This phone number is already registered.',
            'email.unique'    => 'This email address is already registered.',
            'password.min'    => 'Password must be at least 8 characters.',
            'role.in'         => 'Role must be either merchant or customer.',
        ];
    }
}
