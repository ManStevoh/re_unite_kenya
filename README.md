# Reunite — Lost & Found Platform

Recovery network that connects people with their lost items. Privacy-first listings, verified claims, hub handovers, and an operational admin.

| Surface | Stack | Path |
|---|---|---|
| Admin + API | Laravel 13 + Inertia (Vue 3) + Sanctum | `backend/` |
| Mobile | Flutter 3 (Material 3) | `mobile/` |
| Spec | End-to-end product document | [`DOCUMENTATION.md`](DOCUMENTATION.md) |
| API contract | Shared v1 routes + DTOs | [`docs/API_V1.md`](docs/API_V1.md) |

## Local run

### Backend (admin + API)

```bash
cd backend
composer install
copy .env.example .env   # Windows
php artisan key:generate
php artisan migrate:fresh --seed
npm install
npm run dev
```

In another terminal:

```bash
cd backend
php artisan serve
```

- Admin: http://localhost:8000/admin  
- API: http://localhost:8000/api/v1  
- Seed login: `admin@reunite.test` / `password`

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

The Flutter app can run against mock data (`kUseMockApi`) or the local API (`http://127.0.0.1:8000/api/v1`, Android emulator `http://10.0.2.2:8000/api/v1`).

## Seed accounts (after migrate --seed)

| Email | Password | Role | Surface |
|---|---|---|---|
| admin@reunite.test | password | Super admin | Admin web |
| owner@reunite.test | password | User (lost items) | Flutter + API |
| finder@reunite.test | password | User (found items) | API / admin seed |
| hub@reunite.test | password | Hub staff | Flutter mock + API |
| staff@reunite.test | password | Hub staff | Flutter mock alias |

## Phases

All phases from `DOCUMENTATION.md` are in scope for this repo:

0. Foundations (auth, roles, shells)  
1. MVP (reports, matching, claims, chat, hubs, admin queues)  
1.5 Search, OTP, CMS, notification prefs  
2. QR tags, public teasers, reputation, i18n hooks  
3. Multi-org ready, SSO stub, matching hooks  

## Docs

- [`DOCUMENTATION.md`](DOCUMENTATION.md) — modules, screens, security, optimization  
- [`docs/API_V1.md`](docs/API_V1.md) — mobile/admin shared contract  
- [`docs/openapi.yaml`](docs/openapi.yaml) — OpenAPI 3  
