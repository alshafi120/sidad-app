<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id'                => $this->id,
            'full_name'         => $this->full_name,
            'phone'             => $this->phone,
            'email'             => $this->email,
            'role'              => $this->role,
            'is_active'         => $this->is_active,
            'phone_verified_at' => $this->phone_verified_at?->toISOString(),
            'email_verified_at' => $this->email_verified_at?->toISOString(),
            'last_login_at'     => $this->last_login_at?->toISOString(),
            'created_at'        => $this->created_at?->toISOString(),
        ];
    }
}
