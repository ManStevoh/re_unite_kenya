# Reunite backend

Laravel 13 + Inertia Vue 3 admin and `/api/v1` JSON API for the Reunite lost-and-found platform. Local database is **SQLite**.

## Run locally

```bash
cd backend
composer install
npm install
copy .env.example .env   # Windows
php artisan key:generate
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve
```

In another terminal:

```bash
npm run dev
```

Admin: [http://localhost:8000/admin/login](http://localhost:8000/admin/login)  
Public teasers: [http://localhost:8000](http://localhost:8000)  
API base: [http://localhost:8000/api/v1](http://localhost:8000/api/v1)

Queue worker (matching + notifications):

```bash
php artisan queue:work
```

`QUEUE_CONNECTION=database` is the default. Horizon is not required.

## Seed accounts

All passwords are `password`.

| Email | Role |
|---|---|
| `admin@reunite.test` | `super_admin` |
| `owner@reunite.test` | `user` |
| `finder@reunite.test` | `user` |
| `hub@reunite.test` | `user` + `hub_staff` |
| `staff@reunite.test` | `user` + `hub_staff` (Flutter demo alias) |

## API token

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"owner@reunite.test\",\"password\":\"password\",\"device_name\":\"cli\"}"
```

Use the returned `token` as `Authorization: Bearer {token}`.

Phone OTP codes are hashed in `otp_codes` and printed to the Laravel log in local environments.

## Tests

```bash
php artisan test
```

Feature tests cover teaser privacy (no serial / hidden notes / exact coordinates) and report policies (user A cannot patch user B).

## Search

`App\Domain\Search\SearchEngine` is bound to a SQLite/MySQL `LIKE` implementation. Bind a Scout/Meilisearch engine later without changing controllers.
