<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ChangePasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use App\Services\OtpService;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    use ApiResponder;

    public function __construct(
        private readonly AuthService $authService,
        private readonly OtpService $otpService,
    ) {}

    /**
     * Register a new user and send OTP.
     *
     * POST /api/auth/register
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());

        // Auto-send OTP after registration
        $this->otpService->generateAndSend($result['user'], 'email');

        return $this->created([
            'user'  => new UserResource($result['user']),
            'token' => $result['token'],
            'requires_verification' => true,
        ], 'Registration successful. Verification code sent to your email.');
    }

    /**
     * Login and get access token.
     *
     * POST /api/auth/login
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login(
            $request->input('email'),
            $request->input('password'),
            $request->input('device_name'),
        );

        $user = $result['user'];
        $requiresVerification = $user->email_verified_at === null;

        // If user is not verified, send OTP again
        if ($requiresVerification) {
            $this->otpService->generateAndSend($user, 'email');
        }

        return $this->success([
            'user'  => new UserResource($user),
            'token' => $result['token'],
            'requires_verification' => $requiresVerification,
        ], 'Login successful.');
    }

    /**
     * Verify OTP code.
     *
     * POST /api/auth/verify-otp
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string|size:6',
        ]);

        $this->otpService->verify($request->user(), $request->input('code'));

        return $this->success([
            'user' => new UserResource($request->user()->fresh()),
        ], 'تم التحقق بنجاح.');
    }

    /**
     * Resend OTP code.
     *
     * POST /api/auth/resend-otp
     */
    public function resendOtp(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $this->otpService->canResend($user)) {
            return $this->error('لقد تجاوزت الحد الأقصى لإعادة الإرسال. حاول بعد قليل.', 429);
        }

        $this->otpService->generateAndSend($user, 'email');

        return $this->success(message: 'تم إرسال رمز التحقق مجدداً.');
    }

    /**
     * Logout and revoke current token.
     *
     * POST /api/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return $this->success(message: 'Logged out successfully.');
    }

    /**
     * Get authenticated user profile.
     *
     * GET /api/profile
     */
    public function profile(Request $request): JsonResponse
    {
        return $this->success(
            new UserResource($request->user()),
            'Profile retrieved successfully.',
        );
    }

    /**
     * Change password.
     *
     * PUT /api/profile/password
     */
    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $this->authService->changePassword(
            $request->user(),
            $request->input('current_password'),
            $request->input('new_password'),
        );

        return $this->success(message: 'Password changed successfully.');
    }
}
