<?php

declare(strict_types=1);

namespace App\Services;

use App\Exceptions\BusinessException;
use App\Mail\OtpMail;
use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    /**
     * Generate a 6-digit OTP, hash it, and send the plaintext via email.
     */
    public function generateAndSend(User $user, string $type = 'email'): void
    {
        // Invalidate any existing OTPs for this user
        OtpCode::where('user_id', $user->id)
            ->whereNull('verified_at')
            ->delete();

        // Generate a random 6-digit code (uses config for length)
        $length = (int) config('sidad.otp.length', 6);
        $max = (int) str_repeat('9', $length);
        $code = str_pad((string) random_int(0, $max), $length, '0', STR_PAD_LEFT);

        // Store HASHED code in database (never store OTP as plaintext)
        $expiryMinutes = (int) config('sidad.otp.expiry_minutes', 5);
        OtpCode::create([
            'user_id' => $user->id,
            'code' => Hash::make($code),
            'type' => $type,
            'expires_at' => now()->addMinutes($expiryMinutes),
            'attempts' => 0,
        ]);

        // Send plaintext code via email
        if ($type === 'email' && $user->email) {
            Mail::to($user->email)->send(new OtpMail(
                code: $code,
                userName: $user->full_name,
            ));
        }
    }

    /**
     * Verify an OTP code for a user.
     *
     * @throws BusinessException
     */
    public function verify(User $user, string $code): void
    {
        $maxAttempts = (int) config('sidad.otp.max_attempts', 5);

        // Get the latest unverified OTP for this user
        $otp = OtpCode::where('user_id', $user->id)
            ->whereNull('verified_at')
            ->latest()
            ->first();

        if (! $otp) {
            throw new BusinessException('رمز التحقق غير صحيح.', 422);
        }

        // Check max failed attempts
        if (($otp->attempts ?? 0) >= $maxAttempts) {
            $otp->delete(); // Invalidate the OTP after too many attempts
            throw new BusinessException('تم تجاوز الحد الأقصى للمحاولات. أعد إرسال رمز جديد.', 429);
        }

        if (! $otp->isValid()) {
            throw new BusinessException('انتهت صلاحية رمز التحقق. أعد الإرسال.', 422);
        }

        // Compare submitted code against hashed code
        if (! Hash::check($code, $otp->code)) {
            // Increment failed attempts
            $otp->increment('attempts');
            $remaining = $maxAttempts - $otp->attempts;
            throw new BusinessException("رمز التحقق غير صحيح. متبقي {$remaining} محاولات.", 422);
        }

        // Mark OTP as verified
        $otp->update(['verified_at' => now()]);

        // Mark user email as verified
        $user->update(['email_verified_at' => now()]);
    }

    /**
     * Check rate limit: max 3 OTPs per 10 minutes.
     */
    public function canResend(User $user): bool
    {
        $recentCount = OtpCode::where('user_id', $user->id)
            ->where('created_at', '>=', now()->subMinutes(10))
            ->count();

        return $recentCount < 3;
    }
}
