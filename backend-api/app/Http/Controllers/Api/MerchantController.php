<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class MerchantController extends Controller
{
    use ApiResponder;

    /**
     * Display a listing of the merchants.
     *
     * GET /api/merchants
     */
    public function index(Request $request): JsonResponse
    {
        $merchants = User::where('role', 'merchant')
            ->withCount(['activityLogs'])
            ->orderBy('created_at', 'desc')
            ->get();

        $data = $merchants->map(fn(User $merchant) => $this->transformMerchant($merchant))->toArray();

        return $this->success($data, 'Merchants retrieved successfully.');
    }

    /**
     * Store a newly created merchant in storage.
     *
     * POST /api/merchants
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users,email',
            'phone'    => 'required|string|max:20|unique:users,phone',
            'password' => 'required|string|min:8',
        ]);

        $merchant = User::create([
            'full_name' => $validated['name'],
            'email'     => $validated['email'],
            'phone'     => $validated['phone'],
            'password'  => $validated['password'], // Handled by Model cast
            'role'      => 'merchant',
            'is_active' => false, // Pending approval
        ]);

        return $this->created(
            $this->transformMerchant($merchant),
            'Merchant created successfully.',
        );
    }

    /**
     * Update the specified merchant in storage.
     *
     * PUT /api/merchants/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $merchant = User::where('role', 'merchant')->findOrFail($id);

        $validated = $request->validate([
            'name'      => 'nullable|string|max:255',
            'email'     => 'nullable|string|email|max:255|unique:users,email,' . $merchant->id,
            'phone'     => 'nullable|string|max:20|unique:users,phone,' . $merchant->id,
            'status'    => 'nullable|string|in:active,suspended,expired',
            'is_active' => 'nullable|boolean',
        ]);

        $updateData = [];
        if (isset($validated['name'])) {
            $updateData['full_name'] = $validated['name'];
        }
        if (isset($validated['email'])) {
            $updateData['email'] = $validated['email'];
        }
        if (isset($validated['phone'])) {
            $updateData['phone'] = $validated['phone'];
        }
        if (isset($validated['is_active'])) {
            $updateData['is_active'] = $validated['is_active'];
        } elseif (isset($validated['status'])) {
            $updateData['is_active'] = $validated['status'] === 'active';
        }

        $merchant->update($updateData);

        return $this->success(
            $this->transformMerchant($merchant),
            'Merchant updated successfully.',
        );
    }

    /**
     * Transform a User model into the Merchant structure expected by the frontend.
     */
    private function transformMerchant(User $merchant): array
    {
        // Use preloaded counts when available, otherwise query
        $customersCount = \App\Models\Customer::where('merchant_id', $merchant->id)->count();
        $debtsCount = \App\Models\Debt::where('merchant_id', $merchant->id)->count();

        return [
            'id'              => $merchant->id,
            'name'            => $merchant->full_name,
            'email'           => $merchant->email,
            'phone'           => $merchant->phone,
            'status'          => $merchant->is_active ? 'active' : 'pending',
            'customers_count' => $customersCount,
            'debts_count'     => $debtsCount,
            'created_at'      => $merchant->created_at?->format('Y-m-d') ?? now()->format('Y-m-d'),
        ];
    }
}

