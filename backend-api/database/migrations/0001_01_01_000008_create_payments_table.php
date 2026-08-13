<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('debt_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('installment_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('paid_by')->constrained('users')->cascadeOnDelete();
            $table->bigInteger('amount');             // in cents
            $table->string('payment_method', 30)->default('cash');
            $table->string('transaction_reference', 100)->unique()->nullable();
            $table->string('status', 20)->default('completed')->index();
            $table->json('metadata')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('paid_at')->useCurrent();
            $table->timestamps();

            $table->index(['debt_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
