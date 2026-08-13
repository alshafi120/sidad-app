<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Payment\StorePaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Payment;
use App\Services\PaymentService;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    use ApiResponder;

    public function __construct(
        private readonly PaymentService $paymentService,
    ) {}

    /**
     * List all payments.
     *
     * GET /api/payments
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Payment::class);

        $payments = $this->paymentService->list(
            $request->user(),
            $request->only(['debt_id', 'installment_id', 'sort_by', 'sort_dir', 'per_page'])
        );

        return response()->json([
            'success' => true,
            'message' => 'Payments retrieved successfully.',
            'data' => PaymentResource::collection($payments),
            'meta' => [
                'current_page' => $payments->currentPage(),
                'last_page' => $payments->lastPage(),
                'per_page' => $payments->perPage(),
                'total' => $payments->total(),
            ],
        ]);
    }

    /**
     * Record a new payment.
     *
     * POST /api/payments
     */
    public function store(StorePaymentRequest $request): JsonResponse
    {
        $payment = $this->paymentService->recordPayment(
            $request->user(),
            $request->validated()
        );

        return $this->created(
            new PaymentResource($payment),
            'Payment recorded successfully.'
        );
    }

    /**
     * Get payment details.
     *
     * GET /api/payments/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $payment = $this->paymentService->find($id, $request->user());

        $this->authorize('view', $payment);

        return $this->success(
            new PaymentResource($payment),
            'Payment details retrieved successfully.'
        );
    }

    /**
     * Get all payments for a specific installment.
     *
     * GET /api/installments/{id}/payments
     */
    public function installmentPayments(Request $request, string $id): JsonResponse
    {
        // Installment authorization is handled in the service via merchant scoped queries
        $payments = $this->paymentService->getPaymentsForInstallment($id, $request->user());

        return $this->success(
            PaymentResource::collection($payments),
            'Installment payments retrieved successfully.'
        );
    }

    /**
     * Get all payments for a specific debt.
     *
     * GET /api/debts/{id}/payments
     */
    public function debtPayments(Request $request, string $id): JsonResponse
    {
        $payments = $this->paymentService->getPaymentsForDebt($id, $request->user());

        return $this->success(
            PaymentResource::collection($payments),
            'Debt payments retrieved successfully.'
        );
    }
}
