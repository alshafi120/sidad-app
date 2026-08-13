<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class SystemController extends Controller
{
    /**
     * Get system audit logs.
     *
     * GET /api/audit-logs
     */
    public function getAuditLogs(Request $request): JsonResponse
    {
        $logs = ActivityLog::with('user')
            ->orderBy('created_at', 'desc')
            ->limit(100)
            ->get();

        $data = $logs->map(function (ActivityLog $log) {
            return [
                'id'         => $log->id,
                'admin_name' => $log->user?->full_name ?? 'نظام سداد التلقائي',
                'action'     => $this->translateAction($log->action, $log->metadata),
                'ip'         => $log->ip_address ?? '127.0.0.1',
                'browser'    => $log->user_agent ? $this->getBrowserFromUserAgent($log->user_agent) : 'System Cron Job',
                'created_at' => $log->created_at?->toISOString() ?? now()->toISOString(),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Audit logs retrieved successfully.',
            'data'    => $data,
        ]);
    }

    /**
     * Get system packages.
     *
     * GET /api/packages
     */
    public function getPackages(Request $request): JsonResponse
    {
        $path = storage_path('app/packages.json');
        if (!File::exists($path)) {
            $this->initializeDefaultPackages($path);
        }

        $packages = json_decode(File::get($path), true);

        return response()->json([
            'success' => true,
            'message' => 'Packages retrieved successfully.',
            'data'    => $packages,
        ]);
    }

    /**
     * Create a new package.
     *
     * POST /api/packages
     */
    public function createPackage(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'          => 'required|string|max:255',
            'price'         => 'required|numeric',
            'interval'      => 'required|string|in:monthly,yearly',
            'features'      => 'required|array',
            'max_customers' => 'required|integer',
            'max_debts'     => 'required|integer',
        ]);

        $path = storage_path('app/packages.json');
        if (!File::exists($path)) {
            $this->initializeDefaultPackages($path);
        }

        $packages = json_decode(File::get($path), true);
        
        $newPackage = [
            'id'            => 'pk' . (count($packages) + 1),
            'name'          => $validated['name'],
            'price'         => (float) $validated['price'],
            'interval'      => $validated['interval'],
            'features'      => $validated['features'],
            'max_customers' => (int) $validated['max_customers'],
            'max_debts'     => (int) $validated['max_debts'],
        ];

        $packages[] = $newPackage;
        File::put($path, json_encode($packages, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        return response()->json([
            'success' => true,
            'message' => 'Package created successfully.',
            'data'    => $newPackage,
        ]);
    }

    /**
     * Update an existing package.
     *
     * PUT /api/packages/{id}
     */
    public function updatePackage(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'name'          => 'nullable|string|max:255',
            'price'         => 'nullable|numeric',
            'interval'      => 'nullable|string|in:monthly,yearly',
            'features'      => 'nullable|array',
            'max_customers' => 'nullable|integer',
            'max_debts'     => 'nullable|integer',
        ]);

        $path = storage_path('app/packages.json');
        if (!File::exists($path)) {
            $this->initializeDefaultPackages($path);
        }

        $packages = json_decode(File::get($path), true);
        $foundIndex = -1;

        foreach ($packages as $index => $pkg) {
            if ($pkg['id'] === $id) {
                $foundIndex = $index;
                break;
            }
        }

        if ($foundIndex === -1) {
            return response()->json(['success' => false, 'message' => 'Package not found.'], 404);
        }

        $updatedPackage = array_merge($packages[$foundIndex], array_filter($validated));
        $packages[$foundIndex] = $updatedPackage;

        File::put($path, json_encode($packages, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        return response()->json([
            'success' => true,
            'message' => 'Package updated successfully.',
            'data'    => $updatedPackage,
        ]);
    }

    /**
     * Get system settings.
     *
     * GET /api/settings
     */
    public function getSettings(Request $request): JsonResponse
    {
        $path = storage_path('app/settings.json');
        if (!File::exists($path)) {
            $this->initializeDefaultSettings($path);
        }

        $settings = json_decode(File::get($path), true);

        return response()->json([
            'success' => true,
            'message' => 'Settings retrieved successfully.',
            'data'    => $settings,
        ]);
    }

    /**
     * Update system settings.
     *
     * PUT /api/settings
     */
    public function updateSettings(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'general'                  => 'nullable|array',
            'general.site_name'        => 'nullable|string|max:255',
            'general.support_email'    => 'nullable|email|max:255',
            'general.currency'         => 'nullable|string|max:10',
            'branding'                 => 'nullable|array',
            'branding.primary_color'   => 'nullable|string|regex:/^#[0-9a-fA-F]{6}$/',
            'branding.logo_url'        => 'nullable|string|max:2048',
            'smtp'                     => 'nullable|array',
            'smtp.host'                => 'nullable|string|max:255',
            'smtp.port'                => 'nullable|integer',
            'smtp.encryption'          => 'nullable|string|max:20',
            'smtp.username'            => 'nullable|string|max:255',
            'sms'                      => 'nullable|array',
            'sms.provider'             => 'nullable|string|max:255',
            'sms.api_key'              => 'nullable|string|max:255',
            'sms.sender_name'          => 'nullable|string|max:255',
            'whatsapp'                 => 'nullable|array',
            'whatsapp.instance_id'     => 'nullable|string|max:255',
            'whatsapp.token'           => 'nullable|string|max:255',
            'payment_methods'          => 'nullable|array',
            'payment_methods.mada'     => 'nullable|boolean',
            'payment_methods.visa'     => 'nullable|boolean',
            'payment_methods.apple_pay'=> 'nullable|boolean',
        ]);

        $path = storage_path('app/settings.json');
        if (!File::exists($path)) {
            $this->initializeDefaultSettings($path);
        }

        $currentSettings = json_decode(File::get($path), true);
        
        // Merge input payload into current settings
        $newSettings = array_replace_recursive($currentSettings, $validated);

        File::put($path, json_encode($newSettings, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        return response()->json([
            'success' => true,
            'message' => 'Settings updated successfully.',
            'data'    => $newSettings,
        ]);
    }

    /**
     * Initialize default packages file.
     */
    private function initializeDefaultPackages(string $path): void
    {
        $defaultPackages = [
            [
                'id'            => 'pk1',
                'name'          => 'الباقة الأساسية (Basic)',
                'price'         => 99.0,
                'interval'      => 'monthly',
                'max_customers' => 100,
                'max_debts'     => 500,
                'features'      => ['لوحة تحكم بسيطة', 'إدارة الديون', 'تنبيهات SMS محدودة', 'دعم عبر البريد الإلكتروني'],
            ],
            [
                'id'            => 'pk2',
                'name'          => 'الباقة المتقدمة (Premium)',
                'price'         => 299.0,
                'interval'      => 'monthly',
                'max_customers' => 1000,
                'max_debts'     => 5000,
                'features'      => ['لوحة تحكم متقدمة مع رسومات بيانية', 'إدارة الديون والأقساط', 'تنبيهات SMS وواتساب غير محدودة', 'دعم فني 24/7', 'تصدير التقارير بصيغة PDF/Excel'],
            ],
            [
                'id'            => 'pk3',
                'name'          => 'باقة الشركات (Enterprise)',
                'price'         => 2499.0,
                'interval'      => 'yearly',
                'max_customers' => 99999,
                'max_debts'     => 99999,
                'features'      => ['ربط API مخصص', 'مدير حساب مخصص', 'تخصيص الهوية بالكامل', 'دعم متعدد الفروع والمستخدمين', 'تقارير وتحليلات مدعومة بالذكاء الاصطناعي'],
            ]
        ];

        // Ensure directories exist
        File::ensureDirectoryExists(dirname($path));
        File::put($path, json_encode($defaultPackages, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }

    /**
     * Initialize default settings file.
     */
    private function initializeDefaultSettings(string $path): void
    {
        $defaultSettings = [
            'general' => [
                'site_name'     => 'منصة سداد للمدفوعات والديون',
                'support_email' => 'support@sidad.co',
                'currency'      => 'SAR',
            ],
            'branding' => [
                'primary_color' => '#312e81',
                'logo_url'      => '/logo.png',
            ],
            'smtp' => [
                'host'       => 'smtp.mailgun.org',
                'port'       => 587,
                'encryption' => 'tls',
                'username'   => 'postmaster@sidad.co',
            ],
            'sms' => [
                'provider'    => 'Taqnyat',
                'api_key'     => '********-****-****-****-************',
                'sender_name' => 'SidadFin',
            ],
            'whatsapp' => [
                'instance_id' => 'inst_82937492',
                'token'       => 'wa_token_98410283478912',
            ],
            'payment_methods' => [
                'mada'      => true,
                'visa'      => true,
                'apple_pay' => true,
            ],
        ];

        File::ensureDirectoryExists(dirname($path));
        File::put($path, json_encode($defaultSettings, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }

    /**
     * Helper to translate technical activity names to human readable Arabic actions.
     */
    private function translateAction(string $action, ?array $metadata): string
    {
        $translations = [
            'login'                       => 'تسجيل دخول إلى النظام',
            'logout'                      => 'تسجيل خروج من النظام',
            'customer_created'            => 'إضافة عميل جديد',
            'customer_updated'            => 'تعديل بيانات عميل',
            'customer_deleted'            => 'حذف عميل من النظام',
            'customer_account_linked'     => 'ربط حساب عميل بتطبيق الموبايل',
            'customer_self_linked'        => 'ربط عميل لنفسه بالتاجر عبر كود الربط',
            'debt_created'                => 'تسجيل دين جديد على عميل',
            'debt_approved'               => 'اعتماد دين معلق',
            'debt_rejected'               => 'رفض طلب دين معلق',
            'payment_recorded'            => 'سداد دفعة من الدين',
            'settings_updated'            => 'تحديث إعدادات النظام',
        ];

        return $translations[$action] ?? $action;
    }

    /**
     * Parse UA to a friendly browser string.
     */
    private function getBrowserFromUserAgent(string $userAgent): string
    {
        if (str_contains($userAgent, 'Chrome')) {
            return 'Chrome Browser';
        } elseif (str_contains($userAgent, 'Safari')) {
            return 'Safari Browser';
        } elseif (str_contains($userAgent, 'Firefox')) {
            return 'Firefox Browser';
        }
        return 'Web Browser / App';
    }
}

