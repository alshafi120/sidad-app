<?php

declare(strict_types=1);

namespace App\Services;

use App\Exceptions\BusinessException;
use App\Models\User;
use App\Traits\LogsActivity;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    use LogsActivity;

    /**
     * Register a new user.
     */
    public function register(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $role = $data['role'] ?? 'customer';

            $user = User::create([
                'full_name' => $data['full_name'],
                'phone' => $data['phone'],
                'email' => $data['email'],
                'password' => $data['password'],
                'role' => $role,
                // Merchants start as pending (inactive) until admin approves
                'is_active' => $role !== 'merchant',
            ]);

            $token = $user->createToken('auth-token')->plainTextToken;

            $this->logActivity($user, 'registered');

            return ['user' => $user, 'token' => $token];
        });
    }

    /**
     * Authenticate user and create token.
     */
    public function login(string $email, string $password, ?string $deviceName = null): array
    {
        $user = User::where('email', $email)
            ->orWhere('phone', $email)
            ->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw new BusinessException('Invalid credentials.', 401);
        }

        // Merchants pending approval get a specific message
        if ($user->isMerchant() && ! $user->is_active) {
            throw new BusinessException('حسابك قيد المراجعة. سيتم إشعارك عند تفعيله.', 403);
        }

        if (! $user->is_active) {
            throw new BusinessException('Your account has been deactivated. Please contact support.', 403);
        }

        $user->update(['last_login_at' => now()]);

        $token = $user->createToken($deviceName ?? 'auth-token')->plainTextToken;

        $this->logActivity($user, 'login');

        return ['user' => $user, 'token' => $token];
    }

    /**
     * Revoke current access token.
     */
    public function logout(User $user): void
    {
        $user->currentAccessToken()->delete();

        $this->logActivity($user, 'logout');
    }

    /**
     * Change user password and revoke other tokens.
     */
    public function changePassword(User $user, string $currentPassword, string $newPassword): void
    {
        if (! Hash::check($currentPassword, $user->password)) {
            throw new BusinessException('Current password is incorrect.', 422);
        }

        DB::transaction(function () use ($user, $newPassword) {
            $user->update(['password' => $newPassword]);

            // Revoke all tokens except current for security
            $currentTokenId = $user->currentAccessToken()->id;
            $user->tokens()->where('id', '!=', $currentTokenId)->delete();
        });

        $this->logActivity($user, 'password_changed');
    }
}
