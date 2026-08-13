# Sidad — Fintech Backend API

> Production-grade Laravel 12 backend for debt management, installment plans, and payment collection.

## Tech Stack

- **Framework:** Laravel 12 (PHP 8.2+)
- **Database:** PostgreSQL (Supabase)
- **Auth:** Laravel Sanctum (token-based)
- **Architecture:** Service Pattern — thin controllers, fat services

## Quick Start

### 1. Install Dependencies

```bash
composer install
```

### 2. Configure Environment

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` and set your **Supabase PostgreSQL** credentials:

```env
DB_CONNECTION=pgsql
DB_HOST=your-project.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-password
```

### 3. Run Migrations & Seed

```bash
php artisan migrate:fresh --seed
```

This creates the database tables and seeds demo accounts:

| Email                | Password   | Role     |
|----------------------|------------|----------|
| admin@sidad.app      | password   | admin    |
| merchant@sidad.app   | password   | merchant |
| customer@sidad.app   | password   | customer |

### 4. Start Dev Server

```bash
php artisan serve
```

API available at `http://localhost:8000/api`

---

## API Endpoints

### Authentication (Public)

| Method | Endpoint             | Description              |
|--------|----------------------|--------------------------|
| POST   | `/api/auth/register` | Register a new user      |
| POST   | `/api/auth/login`    | Login (rate limited 5/min)|

### Protected (Requires `Authorization: Bearer {token}`)

| Method | Endpoint              | Description         |
|--------|-----------------------|---------------------|
| POST   | `/api/auth/logout`    | Logout / revoke token |
| GET    | `/api/profile`        | Get current user    |
| PUT    | `/api/profile/password` | Change password   |

---

## API Usage Examples

### Register

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "full_name": "Ahmad Ali",
    "phone": "+966501234567",
    "email": "ahmad@example.com",
    "password": "secret123",
    "password_confirmation": "secret123",
    "role": "merchant"
  }'
```

### Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "admin@sidad.app",
    "password": "password"
  }'
```

### Get Profile

```bash
curl http://localhost:8000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## Response Format

### Success
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "user": { "id": "...", "full_name": "...", "role": "merchant" },
    "token": "1|abc..."
  }
}
```

### Error
```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {
    "email": ["This email address is already registered."]
  }
}
```

---

## Project Structure

```
app/
├── Exceptions/
│   └── BusinessException.php       # Domain error handling
├── Http/
│   ├── Controllers/Api/
│   │   └── AuthController.php      # Thin auth controller
│   ├── Middleware/
│   │   ├── ForceJsonResponse.php   # Force JSON on all API requests
│   │   ├── RoleMiddleware.php      # Role-based access control
│   │   └── SecurityHeaders.php     # XSS, clickjack protection
│   ├── Requests/Auth/
│   │   ├── RegisterRequest.php     # Registration validation
│   │   ├── LoginRequest.php        # Login validation
│   │   └── ChangePasswordRequest.php
│   └── Resources/
│       └── UserResource.php        # User API serialization
├── Models/
│   ├── User.php                    # UUID, Sanctum, role helpers
│   └── ActivityLog.php             # Login/logout tracking
├── Providers/
│   └── AppServiceProvider.php      # Rate limiters
├── Services/
│   └── AuthService.php             # All auth business logic
├── Traits/
│   └── ApiResponder.php            # Standardized JSON responses
config/
│   └── sidad.php                   # App-specific configuration
database/
├── migrations/
│   ├── 000000_create_users_table.php
│   ├── 000003_create_personal_access_tokens_table.php
│   └── 000004_create_activity_logs_table.php
└── seeders/
    └── DatabaseSeeder.php          # Demo accounts
```

---

## Security Features

- **Rate Limiting:** Login throttled to 5 attempts/minute per email+IP
- **Security Headers:** X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- **Password Hashing:** Bcrypt with 12 rounds
- **Token Auth:** Sanctum bearer tokens (no cookies needed for mobile)
- **Activity Logging:** All login/logout/password changes tracked with IP and user agent
- **Role Middleware:** `role:admin`, `role:merchant,customer`
- **Force JSON:** All API responses guaranteed JSON format
- **Input Validation:** FormRequest classes with custom error messages

---

## License

Proprietary — Sidad Fintech Platform.
