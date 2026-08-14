<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DebtController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Sidad Fintech Platform
|--------------------------------------------------------------------------
|
| All routes are prefixed with /api automatically by Laravel.
|
*/

Route::get('/health-check', function () {
    return response()->json(['success' => true, 'message' => 'Backend is healthy']);
});

// ─── Public Auth Routes ───────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])
        ->middleware('throttle:5,1'); // 5 registrations per minute
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:login');
});

// ─── Protected Routes (require Sanctum token) ────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // OTP verification (accessible before email is verified)
    Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])
        ->middleware('throttle:10,1'); // 10 attempts per minute
    Route::post('/auth/resend-otp', [AuthController::class, 'resendOtp'])
        ->middleware('throttle:3,10'); // 3 attempts per 10 minutes

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Profile
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile/password', [AuthController::class, 'changePassword']);

    // ── Admin-only routes ─────────────────────────────────────
    Route::middleware('role:admin')->group(function () {
        Route::get('/merchants', [\App\Http\Controllers\Api\MerchantController::class, 'index']);
        Route::post('/merchants', [\App\Http\Controllers\Api\MerchantController::class, 'store']);
        Route::put('/merchants/{id}', [\App\Http\Controllers\Api\MerchantController::class, 'update']);
        Route::get('/audit-logs', [\App\Http\Controllers\Api\SystemController::class, 'getAuditLogs']);
        Route::post('/packages', [\App\Http\Controllers\Api\SystemController::class, 'createPackage']);
        Route::put('/packages/{id}', [\App\Http\Controllers\Api\SystemController::class, 'updatePackage']);
        Route::get('/settings', [\App\Http\Controllers\Api\SystemController::class, 'getSettings']);
        Route::put('/settings', [\App\Http\Controllers\Api\SystemController::class, 'updateSettings']);
    });

    // Public/general auth routes
    Route::get('/packages', [\App\Http\Controllers\Api\SystemController::class, 'getPackages']);

    // ── Merchant + Admin routes ───────────────────────────────
    Route::middleware('role:admin,merchant')->group(function () {
        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::get('/merchants/dashboard', [DashboardController::class, 'index']);

        // Customers
        Route::post('/customers/{id}/link', [CustomerController::class, 'linkAccount']);
        Route::apiResource('customers', CustomerController::class);

        // Debts
        Route::get('/debts', [DebtController::class, 'index']);
        Route::post('/debts', [DebtController::class, 'store']);
        Route::get('/debts/{id}', [DebtController::class, 'show']);
        Route::patch('/debts/{id}/approve', [DebtController::class, 'approve']);
        Route::patch('/debts/{id}/reject', [DebtController::class, 'reject']);

        // Payments
        Route::get('/payments', [PaymentController::class, 'index']);
        Route::post('/payments', [PaymentController::class, 'store']);
        Route::get('/payments/{id}', [PaymentController::class, 'show']);
        Route::get('/debts/{id}/payments', [PaymentController::class, 'debtPayments']);

        // Installment Payments
        Route::get('/installments/{id}/payments', [PaymentController::class, 'installmentPayments']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
    });

    // ── Customer routes ───────────────────────────────────────
    Route::middleware('role:customer')->group(function () {
        Route::get('/customer/dashboard', [DashboardController::class, 'customerDashboard']);
        Route::post('/customer/link-merchant', [CustomerController::class, 'linkMerchant']);
    });
});
