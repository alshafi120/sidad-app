<?php

declare(strict_types=1);

namespace App\Traits;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Facades\Cache;

trait LogsActivity
{
    /**
     * Log user activity to the activity_logs table.
     */
    protected function logActivity(User $user, string $action, ?array $metadata = null): void
    {
        ActivityLog::create([
            'user_id' => $user->id,
            'action' => $action,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'metadata' => $metadata,
        ]);
    }

    /**
     * Clear the dashboard cache for a specific user.
     */
    protected function forgetDashboardCache(User $user): void
    {
        Cache::forget("dashboard:{$user->id}");
    }
}
