# Reunite API v1 — Shared Contract

Base URL (local): `http://127.0.0.1:8000/api/v1`  
Auth: `Authorization: Bearer {token}`  
JSON only. Validation errors: `422` with `{ message, errors }`.

## Auth
- POST `/auth/register` `{ name, display_name, email, password, password_confirmation, city?, terms }`
- POST `/auth/login` `{ email, password, device_name }` → `{ token, refresh_token, user }`
- POST `/auth/refresh` `{ refresh_token }`
- POST `/auth/logout`
- POST `/auth/forgot-password` `{ email }`
- POST `/auth/reset-password` `{ email, token, password, password_confirmation }`
- POST `/auth/email/verify` `{ id, hash }` or signed
- POST `/auth/phone/otp/send` `{ phone }`
- POST `/auth/phone/otp/confirm` `{ phone, code }`

## Me
- GET/PATCH `/me`
- GET `/me/devices`  DELETE `/me/devices/{id}`
- GET/PATCH `/me/notification-preferences`
- POST `/me/data-export`  POST `/me/deactivate`  POST `/me/delete`

## Catalog
- GET `/categories`
- GET `/hubs`  GET `/hubs/{id}`
- GET `/cms/{slug}`

## Reports
- GET `/reports?type=&status=&category_id=&q=&lat=&lng=&radius=`
- POST `/reports`
- GET `/reports/{id}` (teaser unless owner/staff/admin/approved claimant)
- PATCH `/reports/{id}`
- POST `/reports/{id}/submit`
- POST `/reports/{id}/close`
- GET `/reports/{id}/matches`
- POST `/reports/{id}/media`

## Claims / chat / handover
- POST `/claims`  GET `/claims/{id}`
- POST `/claims/{id}/answers`  POST `/claims/{id}/evidence`  POST `/claims/{id}/withdraw`
- GET `/conversations`  GET `/conversations/{id}/messages`  POST `/conversations/{id}/messages`
- POST `/handovers`  POST `/handovers/{id}/confirm`

## Other
- GET `/notifications`  POST `/notifications/{id}/read`
- POST `/flags`
- GET `/search?q=&type=&category_id=`
- GET `/tags/{code}` (Phase 2 QR)
- POST `/tips` (Phase 2, stub OK)

## Report payload (create)
```json
{
  "type": "lost|found",
  "title": "Black leather wallet",
  "category_id": 1,
  "description": "public blurb",
  "hidden_notes": "initials JK inside",
  "serial": "optional",
  "attributes": { "color": "black", "brand": "Fossil" },
  "lat": -1.2921,
  "lng": 36.8219,
  "place_name": "City Mall, Level 2",
  "occurred_at": "2026-08-20T14:00:00Z",
  "custody": "with_finder|at_hub",
  "hub_id": null,
  "visibility": "public_teaser|private_match_only"
}
```

## Teaser DTO (public)
`id, type, title, category, color, area, occurred_on, thumbnail, hub_name`  
Never: serial, hidden_notes, exact lat/lng, owner contact, ID photos.

## User DTO
`id, display_name, avatar_url, city, email_verified, phone_verified, verification_level, member_since, stats`
