<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\StoreCustomerRequest;
use App\Http\Requests\Customer\UpdateCustomerRequest;
use App\Http\Resources\CustomerResource;
use App\Services\CustomerService;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    use ApiResponder;

    public function __construct(
        private readonly CustomerService $customerService,
    ) {}

    /**
     * List customers with search, filter, pagination.
     *
     * GET /api/customers?search=ahmad&is_active=true&sort_by=full_name&sort_dir=asc&per_page=20
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', \App\Models\Customer::class);

        $customers = $this->customerService->list(
            $request->user(),
            $request->only(['search', 'is_active', 'sort_by', 'sort_dir', 'per_page']),
        );

        return response()->json([
            'success' => true,
            'message' => 'Customers retrieved successfully.',
            'data'    => CustomerResource::collection($customers),
            'meta'    => [
                'current_page' => $customers->currentPage(),
                'last_page'    => $customers->lastPage(),
                'per_page'     => $customers->perPage(),
                'total'        => $customers->total(),
            ],
        ]);
    }

    /**
     * Get single customer.
     *
     * GET /api/customers/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $customer = $this->customerService->find($id, $request->user());

        $this->authorize('view', $customer);

        return $this->success(
            new CustomerResource($customer),
            'Customer retrieved successfully.',
        );
    }

    /**
     * Create new customer.
     *
     * POST /api/customers
     */
    public function store(StoreCustomerRequest $request): JsonResponse
    {
        $customer = $this->customerService->create(
            $request->user(),
            $request->validated(),
        );

        return $this->created(
            new CustomerResource($customer),
            'Customer created successfully.',
        );
    }

    /**
     * Update customer.
     *
     * PUT /api/customers/{id}
     */
    public function update(UpdateCustomerRequest $request, string $id): JsonResponse
    {
        $customer = $this->customerService->find($id, $request->user());

        $this->authorize('update', $customer);

        $customer = $this->customerService->update(
            $customer,
            $request->validated(),
            $request->user(),
        );

        return $this->success(
            new CustomerResource($customer),
            'Customer updated successfully.',
        );
    }

    /**
     * Delete customer (soft delete).
     *
     * DELETE /api/customers/{id}
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $customer = $this->customerService->find($id, $request->user());

        $this->authorize('delete', $customer);

        $this->customerService->delete($customer, $request->user());

        return $this->success(message: 'Customer deleted successfully.');
    }

    /**
     * Link a customer record to a real customer user.
     *
     * POST /api/customers/{id}/link
     */
    public function linkAccount(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'phone' => 'required_without:link_code|string|nullable',
            'link_code' => 'required_without:phone|string|nullable',
        ]);

        $customer = $this->customerService->find($id, $request->user());
        $this->authorize('update', $customer);

        $phone = $request->input('phone');
        $linkCode = $request->input('link_code');

        $user = null;
        if ($phone) {
            // Find by phone
            $user = \App\Models\User::where('role', 'customer')
                ->where(function($q) use ($phone) {
                    $escapedPhone = str_replace(['\\', '%', '_'], ['\\\\', '\%', '\_'], $phone);
                    $q->where('phone', $phone)
                      ->orWhere('phone', 'like', "%{$escapedPhone}");
                })->first();
        } else if ($linkCode) {
            // Find by UUID, email or phone
            $user = \App\Models\User::where('role', 'customer')
                ->where(function($q) use ($linkCode) {
                    $q->where('id', $linkCode)
                      ->orWhere('email', $linkCode)
                      ->orWhere('phone', $linkCode);
                })->first();
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'لم يتم العثور على حساب عميل مطابق للمعلومات المدخلة.',
            ], 404);
        }

        // Link
        $customer->user_id = $user->id;
        $customer->save();

        $this->customerService->logActivity($request->user(), 'customer_account_linked', [
            'customer_id' => $customer->id,
            'user_id' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم ربط حساب العميل بنجاح.',
            'data' => new CustomerResource($customer),
        ]);
    }

    /**
     * Link the logged-in customer user to a merchant.
     *
     * POST /api/customer/link-merchant
     */
    public function linkMerchant(Request $request): JsonResponse
    {
        $request->validate([
            'merchant_code' => 'required|string',
        ]);

        $user = $request->user();
        $merchantCode = $request->input('merchant_code');

        // 1. Find the merchant
        $merchant = \App\Models\User::where('role', 'merchant')
            ->where(function($q) use ($merchantCode) {
                $q->where('id', $merchantCode)
                  ->orWhere('phone', $merchantCode)
                  ->orWhere('email', $merchantCode);
            })->first();

        if (!$merchant) {
            return response()->json([
                'success' => false,
                'message' => 'لم يتم العثور على تاجر مطابق للمعلومات المدخلة.',
            ], 404);
        }

        // 2. Find the customer record registered by this merchant with the customer's phone/email
        $customer = \App\Models\Customer::where('merchant_id', $merchant->id)
            ->where(function($q) use ($user) {
                $q->where('phone', $user->phone)
                  ->orWhere('email', $user->email);
            })->first();

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'لم يقم التاجر بتسجيل رقم هاتفك لديه بعد. يرجى الطلب من التاجر إضافة رقمك.',
            ], 404);
        }

        // 3. Link customer user
        $customer->user_id = $user->id;
        $customer->save();

        $this->customerService->logActivity($merchant, 'customer_self_linked', [
            'customer_id' => $customer->id,
            'user_id' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم ربط حسابك بالتاجر بنجاح ومزامنة المديونيات.',
            'data' => [
                'merchant_id'   => $merchant->id,
                'merchant_name' => $merchant->full_name,
                'customer_id'   => $customer->id,
            ]
        ]);
    }
}
