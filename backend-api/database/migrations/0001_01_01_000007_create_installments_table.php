<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('installments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('debt_id')->constrained()->cascadeOnDelete();
            $table->integer('installment_number');
            $table->bigInteger('amount');            // in cents
            $table->bigInteger('paid_amount')->default(0);
            $table->string('status', 20)->default('upcoming')->index();
            $table->date('due_date')->index();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->unique(['debt_id', 'installment_number']);
            $table->index(['due_date', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('installments');
    }
};
