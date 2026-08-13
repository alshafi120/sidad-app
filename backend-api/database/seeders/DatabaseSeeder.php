<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\User;
use App\Models\Customer;
use App\Models\Debt;
use App\Services\DebtService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create default admin user
        User::updateOrCreate(
            ['email' => 'admin@sidad.app'],
            [
                'full_name' => 'Sidad Admin',
                'phone'     => '+966500000000',
                'password'  => 'password',
                'role'      => 'admin',
                'is_active' => true,
            ]
        );

        // Create demo merchant
        $merchant = User::updateOrCreate(
            ['email' => 'merchant@sidad.app'],
            [
                'full_name' => 'Demo Merchant',
                'phone'     => '+966500000001',
                'password'  => 'password',
                'role'      => 'merchant',
                'is_active' => true,
            ]
        );

        // Create demo customer user
        User::updateOrCreate(
            ['email' => 'customer@sidad.app'],
            [
                'full_name' => 'Demo Customer',
                'phone'     => '+966500000002',
                'password'  => 'password',
                'role'      => 'customer',
                'is_active' => true,
            ]
        );

        // Seed Customers for the Demo Merchant
        $customer1 = Customer::updateOrCreate(
            ['merchant_id' => $merchant->id, 'phone' => '+966500000002'],
            [
                'full_name' => 'محمد أحمد بن صالح',
                'email'     => 'customer@sidad.app',
                'is_active' => true,
            ]
        );

        $customer2 = Customer::updateOrCreate(
            ['merchant_id' => $merchant->id, 'phone' => '772222222'],
            [
                'full_name' => 'علي حسن العطاس',
                'email'     => 'ali@sidad.app',
                'is_active' => true,
            ]
        );

        $customer3 = Customer::updateOrCreate(
            ['merchant_id' => $merchant->id, 'phone' => '773333333'],
            [
                'full_name' => 'عبدالله صالح باوزير',
                'email'     => 'abdullah@sidad.app',
                'is_active' => true,
            ]
        );

        // Seed Debts for these Customers using the DebtService to automatically generate Installments
        $debtService = app(DebtService::class);

        // Only seed debts if none exist to prevent duplicate seed entries
        if (Debt::where('merchant_id', $merchant->id)->count() === 0) {
            // Debt 1: Active Partially Paid (e.g. 1500 SAR, paid 500)
            $debt1 = $debtService->create($merchant, [
                'customer_id'       => $customer1->id,
                'title'             => 'فاتورة مواد بناء وإعمار',
                'description'       => 'شراء أسمنت وحديد لتشطيبات الشقة رقم ٣',
                'total_amount'      => 150000, // 1500.00 SAR in cents
                'installment_count' => 3,
                'due_date'          => now()->addMonths(2)->format('Y-m-d'),
            ]);
            // Approve it
            $debtService->approve($debt1, $merchant);
            // Simulate payments
            $debt1->update([
                'paid_amount'      => 50000, // 500.00 SAR
                'remaining_amount' => 100000,
                'status'           => \App\Enums\DebtStatus::PartiallyPaid,
            ]);
            // Update installment statuses
            $debt1->installments()->first()->update([
                'paid_amount' => 50000,
                'status'      => \App\Enums\InstallmentStatus::Paid,
                'paid_at'     => now(),
            ]);

            // Debt 2: Active / Unpaid (e.g. 3000 SAR)
            $debt2 = $debtService->create($merchant, [
                'customer_id'       => $customer2->id,
                'title'             => 'مبيعات بضائع إلكترونية',
                'description'       => 'شراء شاشة ذكية وهاتف محمول ذكي للعمل',
                'total_amount'      => 300000, // 3000.00 SAR in cents
                'installment_count' => 1,
                'due_date'          => now()->addMonth()->format('Y-m-d'),
            ]);
            // Approve it
            $debtService->approve($debt2, $merchant);
            $debt2->update(['status' => \App\Enums\DebtStatus::Active]);

            // Debt 3: Completed / Fully Paid (e.g. 8000 SAR)
            $debt3 = $debtService->create($merchant, [
                'customer_id'       => $customer3->id,
                'title'             => 'خدمات برمجية وتقنية',
                'description'       => 'تصميم وبرمجة متجر سلة متكامل للعميل',
                'total_amount'      => 800000, // 8000.00 SAR in cents
                'installment_count' => 2,
                'due_date'          => now()->subDays(5)->format('Y-m-d'),
            ]);
            $debtService->approve($debt3, $merchant);
            $debt3->update([
                'paid_amount'      => 800000,
                'remaining_amount' => 0,
                'status'           => \App\Enums\DebtStatus::Completed,
            ]);
            $debt3->installments()->update([
                'paid_amount' => DB::raw('amount'),
                'status'      => \App\Enums\InstallmentStatus::Paid,
                'paid_at'     => now(),
            ]);
        }
    }
}

