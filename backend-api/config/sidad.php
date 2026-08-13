<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Sidad Application Configuration
    |--------------------------------------------------------------------------
    */

    // Pagination
    'pagination' => [
        'per_page' => 15,
        'max_per_page' => 100,
    ],

    // OTP Settings
    'otp' => [
        'length' => 6,
        'expiry_minutes' => 5,
        'max_attempts' => 3,
    ],

    // Financial
    'currency' => env('SIDAD_CURRENCY', 'SAR'),
    'currency_precision' => 2,

    // Roles
    'roles' => [
        'admin',
        'merchant',
        'customer',
    ],

    // Debt
    'debt' => [
        'max_installments' => 60,
        'min_installment_amount' => 100, // in cents (1 SAR)
    ],
];
