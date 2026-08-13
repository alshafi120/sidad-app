<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CustomerResource;
use App\Http\Resources\DebtResource;
use App\Models\Customer;
use App\Models\Debt;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DashboardController extends Controller
{
    /**
     * Get aggregate dashboard statistics for the logged-in merchant.
     *
     * GET /api/dashboard
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = Cache::remember("dashboard:{$user->id}", now()->addSeconds(30), function () use ($request, $user): array {
            if ($user->isAdmin()) {
                // System-wide statistics for Platform Admins
                $totalMerchants = \App\Models\User::where('role', 'merchant')->count();
                $activeMerchants = \App\Models\User::where('role', 'merchant')->where('is_active', true)->count();
                $expiredSubscriptions = \App\Models\User::where('role', 'merchant')->where('is_active', false)->count();
                $expiringSoon = 0; // Can be enhanced later with plans

                $totalCustomers = Customer::count();

                $totals = Debt::selectRaw('
                    COALESCE(SUM(total_amount), 0) / 100.0 as total,
                    COALESCE(SUM(paid_amount), 0) / 100.0 as settled,
                    COALESCE(SUM(remaining_amount), 0) / 100.0 as pending
                ')->first();

                $monthlyRevenue = \App\Models\Payment::where('status', 'completed')
                    ->where('created_at', '>=', now()->subDays(30))
                    ->sum('amount') / 100.0;

                $topCustomers = Customer::withCount('debts')
                    ->withSum('debts as total_debt', 'total_amount')
                    ->withSum('debts as paid_amount', 'paid_amount')
                    ->orderByDesc('total_debt')
                    ->limit(5)
                    ->get();

                $recentTransactions = Debt::with(['customer', 'merchant'])
                    ->orderBy('created_at', 'desc')
                    ->limit(5)
                    ->get();

                return [
                    'total_merchants'       => (int) $totalMerchants,
                    'active_merchants'      => (int) $activeMerchants,
                    'expired_subscriptions' => (int) $expiredSubscriptions,
                    'expiring_soon'         => (int) $expiringSoon,
                    'total_customers'       => (int) $totalCustomers,
                    'total_debts'           => (float) ($totals->total ?? 0.0),
                    'settled_debts'         => (float) ($totals->settled ?? 0.0),
                    'pending_debts'         => (float) ($totals->pending ?? 0.0),
                    'monthly_revenue'       => (float) $monthlyRevenue,
                    'recent_transactions'   => DebtResource::collection($recentTransactions)->resolve($request),
                    'top_customers'         => CustomerResource::collection($topCustomers)->resolve($request),
                ];
            }

            // Merchant-specific statistics
            $activeCustomers = Customer::where('merchant_id', $user->id)
                ->where('is_active', true)
                ->count();

            $totals = Debt::where('merchant_id', $user->id)
                ->selectRaw('
                COALESCE(SUM(total_amount), 0) / 100.0 as total,
                COALESCE(SUM(paid_amount), 0) / 100.0 as settled,
                COALESCE(SUM(remaining_amount), 0) / 100.0 as pending
            ')
                ->first();

            $topCustomers = Customer::where('merchant_id', $user->id)
                ->withCount('debts')
                ->withSum('debts as total_debt', 'total_amount')
                ->withSum('debts as paid_amount', 'paid_amount')
                ->orderByDesc(
                    Debt::selectRaw('COALESCE(SUM(total_amount), 0)')
                        ->whereColumn('debts.customer_id', 'customers.id')
                        ->whereNull('debts.deleted_at')
                )
                ->limit(5)
                ->get();

            $recentTransactions = Debt::with('customer')
                ->where('merchant_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get();

            return [
                'total_debts' => (float) ($totals->total ?? 0.0),
                'settled_debts' => (float) ($totals->settled ?? 0.0),
                'pending_debts' => (float) ($totals->pending ?? 0.0),
                'active_customers' => (int) $activeCustomers,
                'recent_transactions' => DebtResource::collection($recentTransactions)->resolve($request),
                'top_customers' => CustomerResource::collection($topCustomers)->resolve($request),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Dashboard statistics retrieved successfully.',
            'data' => $data,
        ]);
    }

    /**
     * Get dashboard statistics and merchant debt groups for a customer.
     *
     * GET /api/customer/dashboard
     */
    public function customerDashboard(Request $request): JsonResponse
    {
        $user = $request->user();

        // 1. Fetch customer records associated with this customer user
        $customerRecords = Customer::where('user_id', $user->id)
            ->withCount('debts')
            ->withSum('debts as total_debt', 'total_amount')
            ->withSum('debts as paid_debt', 'paid_amount')
            ->with('merchant')
            ->get();

        // 2. Format merchants list
        $merchants = $customerRecords->map(function ($cust) {
            $totalAmount = (double) (($cust->total_debt ?? 0) / 100);
            $paidAmount = (double) (($cust->paid_debt ?? 0) / 100);
            $remainingAmount = $totalAmount - $paidAmount;

            $status = 'paid';
            if ($remainingAmount > 0) {
                $status = 'pending';
                $hasOverdue = Debt::where('customer_id', $cust->id)
                    ->where('status', 'overdue')
                    ->exists();
                if ($hasOverdue) {
                    $status = 'overdue';
                }
            }

            return [
                'customer_record_id' => $cust->id,
                'merchant_id'        => $cust->merchant->id,
                'merchant_name'      => $cust->merchant->full_name,
                'debt_count'         => $cust->debts_count,
                'total_amount'       => $totalAmount,
                'paid_amount'        => $paidAmount,
                'remaining_amount'   => $remainingAmount,
                'status'             => $status,
            ];
        });

        // 3. Fetch recent transactions
        $customerIds = $customerRecords->pluck('id');
        $recentTransactions = Debt::with('merchant')
            ->whereIn('customer_id', $customerIds)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        $recentTransactionsFormatted = $recentTransactions->map(function ($debt) {
            return [
                'id'               => $debt->id,
                'merchant_id'      => $debt->merchant_id,
                'merchant_name'    => $debt->merchant->full_name,
                'title'            => $debt->title,
                'description'      => $debt->description,
                'total_amount'     => (double) ($debt->total_amount / 100.0),
                'paid_amount'      => (double) ($debt->paid_amount / 100.0),
                'remaining_amount' => (double) ($debt->remaining_amount / 100.0),
                'status'           => $debt->status,
                'created_at'       => $debt->created_at?->toISOString(),
            ];
        });

        // 4. Summarize aggregates
        $totalDebts = (double) ($customerRecords->sum('total_debt') / 100);
        $settledDebts = (double) ($customerRecords->sum('paid_debt') / 100);
        $pendingDebts = $totalDebts - $settledDebts;

        return response()->json([
            'success' => true,
            'message' => 'Customer dashboard retrieved successfully.',
            'data' => [
                'total_debts'         => $totalDebts,
                'settled_debts'       => $settledDebts,
                'pending_debts'       => $pendingDebts,
                'merchants'           => $merchants,
                'recent_transactions' => $recentTransactionsFormatted,
            ],
        ]);
    }
}
