<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Debt\ApproveDebtRequest;
use App\Http\Requests\Debt\RejectDebtRequest;
use App\Http\Requests\Debt\StoreDebtRequest;
use App\Http\Resources\DebtResource;
use App\Services\DebtService;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DebtController extends Controller
{
    use ApiResponder;

    public function __construct(
        private readonly DebtService $debtService,
    ) {}

    /**
     * List all debts.
     *
     * GET /api/debts
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', \App\Models\Debt::class);

        $debts = $this->debtService->list(
            $request->user(),
            $request->only(['customer_id', 'status', 'sort_by', 'sort_dir', 'per_page']),
        );

        return response()->json([
            'success' => true,
            'message' => 'Debts retrieved successfully.',
            'data'    => DebtResource::collection($debts),
            'meta'    => [
                'current_page' => $debts->currentPage(),
                'last_page'    => $debts->lastPage(),
                'per_page'     => $debts->perPage(),
                'total'        => $debts->total(),
            ],
        ]);
    }

    /**
     * Create a new debt.
     *
     * POST /api/debts
     */
    public function store(StoreDebtRequest $request): JsonResponse
    {
        $debt = $this->debtService->create(
            $request->user(),
            $request->validated(),
        );

        return $this->created(
            new DebtResource($debt),
            'Debt created successfully.',
        );
    }

    /**
     * Get debt details.
     *
     * GET /api/debts/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $debt = $this->debtService->find($id, $request->user());

        $this->authorize('view', $debt);

        return $this->success(
            new DebtResource($debt),
            'Debt retrieved successfully.',
        );
    }

    /**
     * Approve a pending debt.
     *
     * PATCH /api/debts/{id}/approve
     */
    public function approve(ApproveDebtRequest $request, string $id): JsonResponse
    {
        $debt = $this->debtService->find($id, $request->user());

        $this->authorize('approve', $debt);

        $debt = $this->debtService->approve($debt, $request->user());

        return $this->success(
            new DebtResource($debt),
            'Debt approved successfully.',
        );
    }

    /**
     * Reject a pending debt.
     *
     * PATCH /api/debts/{id}/reject
     */
    public function reject(RejectDebtRequest $request, string $id): JsonResponse
    {
        $debt = $this->debtService->find($id, $request->user());

        $this->authorize('reject', $debt);

        $debt = $this->debtService->reject($debt, $request->validated('rejection_reason'), $request->user());

        return $this->success(
            new DebtResource($debt),
            'Debt rejected successfully.',
        );
    }
}
