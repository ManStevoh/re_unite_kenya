# Lost & Found Platform — End-to-End Product Specification

**Product name (working):** Reunite  
**Workspace:** `C:\xampp\htdocs\lostandfound`  
**Document type:** Full product, architecture, module, screen, security, and delivery specification  
**Status:** Implemented in-repo (Laravel admin/API + Flutter mobile). See root `README.md`.  
**Last updated:** 2026-08-28

---

## 1. Purpose of this document

This file is the single source of truth for building the platform end to end. It defines:

- What the product is and who it serves
- Every module and how modules connect
- Accounts, roles, and identity
- Admin backend (Laravel + Inertia) screens and capabilities
- Mobile app (Flutter) screens and capabilities
- APIs, data model, matching, claims, and messaging
- Security, privacy, abuse prevention
- Performance and optimization
- Phased delivery so the team can implement without guessing

If a feature is not listed here, it is out of scope until this document is updated.

---

## 2. Product vision

Reunite connects people with their lost items.

A person who lost something can report it. A person (or a trusted hub such as a mall, campus security desk, airport, or transport office) who found something can report it. The platform matches reports, protects identifying details, verifies ownership, and coordinates a safe return.

The product is **not** a public classifieds board. It is a **recovery network** with privacy-first listings, verified claims, and a human-moderated admin backend.

### 2.1 Primary outcomes

1. Increase the rate of successful item returns.
2. Reduce scams, fake claims, and unsafe contact exchange.
3. Give hubs a professional intake and handover workflow.
4. Give admins tools to moderate, resolve disputes, and measure recovery.

### 2.2 Success metrics

| Metric | Definition | Target (v1) |
|---|---|---|
| Time-to-first-match | Minutes from a new report to first candidate match | < 15 minutes for common categories |
| Claim conversion | Matched reports that become verified claims | Track baseline, then improve |
| Return rate | Verified claims marked returned | Track baseline |
| False-claim rate | Claims rejected for failed verification | Keep low; investigate spikes |
| Abuse reports | Flags per 1,000 listings | Keep low |
| App crash-free sessions | Flutter stability | ≥ 99.5% |
| Admin SLA | Flagged content first-reviewed | < 24 hours |

---

## 3. Product principles

1. **Privacy before convenience.** Unique marks, serials, photos of IDs, and exact contents stay hidden until a claim is in progress.
2. **Verify ownership, never guess.** Matching suggests candidates. Humans (owner + finder + optional hub/admin) confirm.
3. **No raw phone-number dump.** Contact happens in-app first. Direct contact is opt-in and logged.
4. **Hubs are first-class.** Many items are found by staff, not by random passers-by.
5. **Admin is operational, not decorative.** The Laravel/Inertia backend is the control room for users, listings, claims, disputes, and trust.
6. **Mobile is the citizen surface.** Flutter is how the public reports, searches, claims, and chats.
7. **Assume bad actors.** Rate-limit, watermark, redact, audit, and make claiming hard for people who do not own the item.

---

## 4. Personas and roles

### 4.1 Personas

| Persona | Goal | Main surface |
|---|---|---|
| Owner | Recover a lost item | Flutter |
| Finder | Return an item they found | Flutter |
| Hub staff | Intake, store, and hand over items at a physical desk | Flutter (hub mode) + Admin web |
| Moderator | Review reports, photos, chats, and claims | Admin (Inertia) |
| Super admin | Configure the platform, roles, and policy | Admin (Inertia) |
| Support agent | Help users complete claims and recover accounts | Admin (Inertia) |
| Guest | Browse public teasers and decide to sign up | Flutter + optional public web |

### 4.2 System roles

| Role | Scope |
|---|---|
| `guest` | Read public teaser cards only |
| `user` | Report lost/found, claim, chat, manage own listings |
| `hub_staff` | Create found reports for a hub, update storage status, complete handovers |
| `hub_manager` | Manage one hub: staff, hours, storage locations, hub analytics |
| `moderator` | Review listings, media, claims, flags, and chats |
| `support` | Account recovery, ticket replies, claim coaching (no destructive config) |
| `admin` | Full operational access except platform-destroying settings |
| `super_admin` | Roles, feature flags, integrations, legal/compliance settings |

A user can hold more than one role (example: a campus officer is `user` + `hub_staff`).

---

## 5. Recommended architecture

```
┌──────────────────────────┐     ┌──────────────────────────┐
│  Flutter mobile          │     │  Laravel + Inertia admin │
│  (iOS / Android)         │     │  (Vue 3 + TypeScript)    │
│  Citizens + hub staff    │     │  Mods, support, admins   │
└────────────┬─────────────┘     └────────────┬─────────────┘
             │ HTTPS JSON + Sanctum           │ Inertia visits
             │                                │ (session cookie)
             └───────────────┬────────────────┘
                             ▼
                    ┌─────────────────┐
                    │  Laravel API    │
                    │  Domain + Jobs  │
                    └────────┬────────┘
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
     MySQL 8           Redis (cache,     Object storage
     (source of        queue, locks)     (photos, docs)
      truth)
           │
           ▼
     Meilisearch / Scout     FCM / APNs          Mail / SMS
     (search + matching      (push)              (OTP, receipts)
      candidate index)
```

### 5.1 Why this split

- **Laravel + Inertia** is ideal for a dense admin: tables, filters, dispute queues, role management, and audit logs. No separate SPA build pipeline for staff.
- **Flutter** is ideal for camera-heavy, location-aware, offline-tolerant citizen flows.
- One Laravel domain serves both. Admin uses session + CSRF. Mobile uses Laravel Sanctum personal access tokens (or cookie-less token auth).

### 5.2 Local development (XAMPP)

| Piece | Local choice |
|---|---|
| PHP / Apache | XAMPP |
| Database | MySQL via XAMPP |
| Admin URL | `http://localhost/lostandfound/public` or a vhost `reunite.test` |
| Queue | Database driver first; Redis later |
| Flutter | Talks to `http://10.0.2.2` (Android emulator) or machine LAN IP |
| Search | MySQL `LIKE` / fulltext in v1; Meilisearch in v1.5 |

### 5.3 Production target

| Piece | Production choice |
|---|---|
| App server | PHP-FPM + Nginx (or Laravel Forge / Vapor later) |
| Queue / cache | Redis + Laravel Horizon |
| Search | Meilisearch or Typesense via Laravel Scout |
| Files | S3-compatible bucket + CDN |
| Push | Firebase Cloud Messaging |
| Observability | Sentry + structured logs + Horizon |

---

## 6. Technology stack

### 6.1 Admin and API (Laravel)

| Layer | Choice | Why |
|---|---|---|
| Framework | Laravel 11+ | Domain, queues, auth, policies |
| Admin UI | Inertia.js + Vue 3 + TypeScript | Modern admin without a detached SPA |
| Styling | Tailwind CSS + Headless UI | Fast, consistent staff UI |
| Auth (admin) | Session + Fortify / Breeze Inertia | Cookie CSRF for browsers |
| Auth (mobile) | Laravel Sanctum tokens | Stateless Flutter clients |
| Authorization | Spatie Laravel Permission | Roles and permissions |
| Media | Spatie Media Library | Item photos, claim evidence |
| Search | Laravel Scout + Meilisearch | Fast item discovery |
| Jobs | Redis + Horizon | Matching, notifications, image processing |
| 2FA (admin) | Fortify TOTP | Protect privileged accounts |
| Audit | `activity_log` table + observers | Who changed what |

### 6.2 Mobile (Flutter)

| Layer | Choice | Why |
|---|---|---|
| UI | Flutter 3, Material 3, custom design tokens | Modern, native feel |
| State | Riverpod | Testable, scalable |
| Routing | go_router | Deep links and guards |
| HTTP | Dio + interceptors | Auth refresh, errors |
| Local store | Drift or Hive + secure storage | Offline drafts, tokens |
| Images | image_picker, flutter_image_compress, cached_network_image | Fast, cheap uploads |
| Maps | google_maps_flutter or mapbox | Last-seen / found location |
| Push | firebase_messaging | Match and chat alerts |
| Design | Custom components, large tap targets, empty states | Trustworthy recovery UX |

### 6.3 Shared contracts

- Versioned JSON API: `/api/v1/...`
- OpenAPI spec generated from Laravel routes or a dedicated `openapi.yaml`
- Shared enums: item status, claim status, category codes, notification types
- Shared error codes so Flutter can map them to UI

---

## 7. Module catalog

Every module below is a bounded area of the product. Implement them as Laravel domain folders (or modules) plus matching Flutter features.

### 7.1 Module map

| ID | Module | Surfaces | v1 |
|---|---|---|---|
| M01 | Identity & accounts | Flutter + Admin | Required |
| M02 | Profiles & trust | Flutter + Admin | Required |
| M03 | Categories & taxonomy | Admin + API | Required |
| M04 | Locations & geospatial | Flutter + Admin | Required |
| M05 | Hubs & storage | Flutter hub mode + Admin | Required |
| M06 | Lost reports | Flutter + Admin | Required |
| M07 | Found reports | Flutter + Admin | Required |
| M08 | Media pipeline | API + workers | Required |
| M09 | Search & discovery | Flutter + Admin | Required |
| M10 | Matching engine | Workers + both UIs | Required |
| M11 | Claims & verification | Flutter + Admin | Required |
| M12 | Recovery & handover | Flutter + Admin | Required |
| M13 | In-app messaging | Flutter + Admin moderate | Required |
| M14 | Notifications | All | Required |
| M15 | Flags, abuse, disputes | Flutter + Admin | Required |
| M16 | Admin operations | Inertia | Required |
| M17 | Analytics & reporting | Admin | Required |
| M18 | Audit & compliance | Admin | Required |
| M19 | Help, legal, CMS | Flutter + Admin | Required |
| M20 | Settings & feature flags | Admin | Required |
| M21 | QR / physical tags | Flutter + Admin | Phase 2 |
| M22 | Rewards & reputation | Flutter + Admin | Phase 2 |
| M23 | Payments / thank-you tips | Flutter + Admin | Phase 2 |
| M24 | Public web teaser | Optional Inertia public pages | Phase 2 |
| M25 | Partner / campus SSO | Admin + API | Phase 3 |
| M26 | Multilingual & accessibility | All | Phase 2 (i18n hooks in v1) |

---

## 8. Module specifications

### M01 — Identity & accounts

**Purpose:** Create, verify, recover, and session-manage every actor.

**Capabilities**

- Email + password registration
- Phone OTP as optional second factor / recovery
- Email verification before creating reports (recommended hard gate)
- Login, logout, refresh, revoke all sessions
- Forgot / reset password
- Social login (Google / Apple) as optional Phase 1.5
- Device registry (name, OS, last IP, last seen)
- Account freeze, ban, and self-deactivation
- Admin impersonation **disabled by default**; if enabled later, full audit + watermark

**Account states**

`pending_verification` → `active` → `restricted` | `suspended` | `banned` | `deactivated` | `deleted` (soft)

**Rules**

- Unverified users can browse teasers only.
- Suspended users can view their own cases but cannot create new reports or claims.
- Banned users are signed out everywhere.

### M02 — Profiles & trust

**Purpose:** Show just enough identity to build trust without leaking personal data.

**Profile fields**

- Display name
- Avatar
- City / area (coarse)
- Member since
- Verified email / phone badges
- Optional government-ID verification status (hub/admin only sees result, not the document after review)
- Trust score (internal; not a public vanity number in v1)
- Stats: reports filed, items returned, claims completed (public counts only)

**Trust signals (internal)**

- Verified contact
- Completed returns
- Rejected claims
- Flags received
- Account age
- Device consistency

### M03 — Categories & taxonomy

**Purpose:** Structured item types so matching and forms stay accurate.

**Suggested top-level categories**

- Documents & IDs
- Wallets & bags
- Phones & tablets
- Computers & accessories
- Keys
- Jewelry & watches
- Clothing & uniforms
- Eyewear
- Cards (bank, transport, membership)
- Pets & pet items
- Vehicles & plates (restricted; extra moderation)
- Other

Each category has:

- Required / optional fields (brand, color, serial, chip number)
- Sensitivity level (`public`, `restricted`, `highly_sensitive`)
- Photo guidance (what to show / hide)
- Default retention period

**Admin can** CRUD categories, attributes, and form schemas without a deploy.

### M04 — Locations & geospatial

**Purpose:** Capture where an item was lost or found without oversharing.

**Location model**

- Point (lat/lng)
- Place name / landmark
- Address (optional, precision-reduced for public)
- Area / geohash for matching
- Map preview

**Privacy**

- Public cards show area, not exact pin (example: “Near City Mall, Level 2”).
- Exact pin visible to: reporter, matched claimant after acceptance, hub staff, moderators.

### M05 — Hubs & storage

**Purpose:** Physical desks that intake and store found items.

**Hub record**

- Name, type (campus, mall, airport, station, office, municipal)
- Address, map, hours
- Contact (internal)
- Storage bays / shelves
- Staff assignments
- Public visibility toggle

**Hub workflows**

1. Staff creates a found report at the desk.
2. Item is tagged with an internal storage code.
3. Matches notify possible owners.
4. Owner claims and books a pickup window.
5. Staff verifies ownership in person and marks `handed_over`.
6. Unclaimed items follow hub retention policy, then archive / dispose (logged).

### M06 — Lost reports

**Purpose:** An owner describes what they lost.

**Fields**

- Title
- Category + attributes
- Description (private notes vs public blurb)
- Distinguishing marks (hidden)
- Serial / ID numbers (hidden)
- Last-seen location + time window
- Photos (optional; faces and document numbers auto-blurred)
- Reward note (text only in v1)
- Visibility: `private_match_only` or `public_teaser`

**Statuses**

`draft` → `submitted` → `under_review` → `published` → `matched` → `claim_in_progress` → `recovered` | `closed` | `expired` | `rejected`

### M07 — Found reports

**Purpose:** A finder or hub records an item they have.

**Extra fields vs lost**

- Current custody: `with_finder` | `at_hub` | `with_staff`
- Storage code
- Found location + time
- Condition
- Sensitive photo set (admin/hub only)

**Public teaser rules**

Show category, color, general area, date found.  
Hide serials, unique engravings, ID photos, card numbers, and tight crop photos that prove ownership.

### M08 — Media pipeline

**Purpose:** Safe, fast, cheap images.

**Pipeline**

1. Client compresses before upload.
2. Direct-to-storage signed upload (or Laravel upload for v1).
3. Queue: strip EXIF, generate variants (`thumb`, `card`, `detail`), auto-blur document MRZ / card numbers (best-effort).
4. Virus / malware scan if objects are user-uploaded files beyond images (Phase 2).
5. CDN delivery.

**Rules**

- Max 6 photos per report in v1.
- No videos in v1.
- Claim evidence stored separately, shorter retention after case close.

### M09 — Search & discovery

**Purpose:** Help people find likely listings without dumping PII.

**Citizen search**

- Text query
- Category
- Date range
- Area / radius
- Lost vs found
- Hub filter

**Admin search**

- Everything citizens can search
- Plus user, status, flag, storage code, exact serial (permission-gated)

**Ranking**

- Recency
- Distance
- Category match
- Completeness of listing
- Trust of reporter (slight boost, not dominant)

### M10 — Matching engine

**Purpose:** Suggest likely pairs. Never auto-close a case.

**Inputs**

- Category
- Color / brand / model
- Time windows (lost after found is a negative signal)
- Distance / same hub
- Attribute overlap
- Optional embedding similarity on titles + descriptions (Phase 2)

**Outputs**

- Ranked candidate list with score + reasons (`same_category`, `nearby`, `color`, `date_overlap`)
- Notification to both sides when score ≥ threshold
- Admin “forced match” for support cases

**Processing**

- On create / update of a report, enqueue `ComputeMatchesJob`
- Recompute nightly for open items
- Deduplicate so users are not spammed

### M11 — Claims & verification

**Purpose:** Prove “this is mine” without teaching scammers the answers.

**Claim flow**

1. User opens a found teaser (or a suggested match).
2. User starts a claim and answers **challenge questions** generated from hidden fields (color of lining, last 4 of serial, sticker, contents).
3. User may upload ownership evidence (receipt, photo of matching set, pet records).
4. Finder / hub / moderator reviews.
5. Claim is `approved`, `needs_more_info`, or `rejected`.
6. On approval, messaging + handover instructions unlock.

**Challenge design**

- Questions drawn from hidden attributes the real owner should know.
- Multiple-choice must include plausible decoys.
- Limited attempts (example: 3), then cooldown + moderator review.

**Statuses**

`draft` → `submitted` → `in_review` → `needs_info` → `approved` | `rejected` | `withdrawn` | `expired`

### M12 — Recovery & handover

**Purpose:** Finish the return safely.

**Handover types**

- Hub pickup (preferred)
- Public place meetup (discouraged; safety tips required)
- Staff delivery (hub-only, optional)

**Handover record**

- Type, time window, location
- Parties present
- Confirmation codes (6-digit, one-time)
- Photos of handover (optional)
- Both parties tap “Item received / Item given”
- Case closes to `recovered`

### M13 — In-app messaging

**Purpose:** Coordinate return without leaking phone numbers.

**Rules**

- A thread is created only after a match is accepted **or** a claim is submitted (configurable).
- Messages are text + image only in v1.
- Phone numbers and payment-request patterns are flagged.
- Users can block, mute, and report a thread.
- Moderators can read threads that are flagged or attached to a dispute.
- Retention: keep until case + legal hold period, then purge.

### M14 — Notifications

**Channels**

- In-app inbox
- Push (FCM)
- Email
- SMS (OTP and critical claim updates only)

**Events**

- Email / phone verification
- Report approved / rejected
- New match
- Claim submitted / needs info / decided
- New chat message
- Handover reminder
- Item about to expire
- Admin announcement (rare)

**Preferences**

Per-event toggles. Security messages (password changed, new device) cannot be disabled.

### M15 — Flags, abuse, disputes

**User can flag**

- Fake listing
- Stolen-goods suspicion
- Harassment
- Spam
- Impersonation
- Unsafe meetup request

**Dispute types**

- Two owners claim the same item
- Finder refuses handover after approved claim
- Wrong item collected
- Hub storage mismatch

**Admin queue**

Priority = severity + item value/sensitivity + user trust.

### M16 — Admin operations

See [Section 14](#14-admin-backend-laravel--inertia--all-screens).

### M17 — Analytics & reporting

**Dashboards**

- Reports created (lost vs found)
- Matches generated / accepted
- Claims approved / rejected
- Returns completed
- Active hubs and storage occupancy
- Funnel: signup → verify → first report → match → return
- Moderator workload and SLA

**Exports**

CSV for date-ranged operational reports. No bulk PII export without `super_admin` + reason logged.

### M18 — Audit & compliance

Log at minimum:

- Login / logout / failed login
- Role changes
- Listing status changes
- Claim decisions
- Message moderator access
- Data export / delete requests
- Impersonation (if ever enabled)

Retention policy documented in admin Settings.

### M19 — Help, legal, CMS

- FAQ
- How claiming works
- Safety tips
- Privacy policy
- Terms
- Community guidelines
- Contact support

Admin edits pages via a simple CMS (Markdown or block editor).

### M20 — Settings & feature flags

- Registration open/closed
- Required verification gates
- Match score threshold
- Claim attempt limits
- Retention days by category
- Guest browse on/off
- Maintenance banner
- Map provider keys (server-side)

### M21 — QR / physical tags (Phase 2)

Users buy or print a tag. Scanning opens a secure “I found this” flow that notifies the owner without showing their phone number.

### M22 — Rewards & reputation (Phase 2)

Thank-you badges, finder reputation, optional campus leaderboards. Do not gamify in a way that encourages fake finds.

### M23 — Payments (Phase 2)

Optional thank-you tip after a verified return. Escrow is out of scope until legal review.

### M24 — Public web teaser (Phase 2)

Marketing + limited public search on Inertia public pages. Full reporting stays in the app (or later a public web form).

---

## 9. Domain model (logical)

### 9.1 Core entities

```
User
Profile
Role / Permission
Device
Hub
HubStaff
StorageLocation
Category
CategoryAttribute
ItemReport          (type: lost | found)
ItemAttributeValue
MediaAsset
MatchCandidate
Claim
ClaimAnswer
ClaimEvidence
Conversation
Message
Handover
Flag
Dispute
Notification
AuditLog
Setting
CmsPage
```

### 9.2 Item report (canonical)

One table `item_reports` with `type` enum. Lost and found share matching, media, and status machinery. Type-specific columns are nullable.

### 9.3 Suggested status machines

**ItemReport**

```
draft → submitted → under_review → published → matched
published → expired | closed | rejected
matched → claim_in_progress → recovered | closed
```

**Claim**

```
submitted → in_review → needs_info → in_review
in_review → approved | rejected
approved → handover_scheduled → completed
any open → withdrawn | expired
```

### 9.4 Key indexes (v1)

- `item_reports(type, status, category_id, lost_or_found_at)`
- `item_reports(geohash, status)`
- `item_reports(user_id, status)`
- `match_candidates(lost_id, found_id)` unique
- `claims(item_report_id, claimant_id, status)`
- `messages(conversation_id, created_at)`
- `notifications(user_id, read_at, created_at)`
- `activity_log(subject_type, subject_id, created_at)`

---

## 10. Accounts functionality (full)

### 10.1 Registration

**Flutter screens:** Welcome → Register → Verify email / OTP → Profile setup → Home

**Fields**

- Full name (legal, private)
- Display name (public)
- Email (unique)
- Phone (unique, optional at signup, required before first claim)
- Password (min 10, breach-check via HaveIBeenPwned k-anonymity API or local zxcvbn)
- City / country
- Accept terms + privacy
- Age confirmation (must be 16+ or local equivalent; under-18 restricted from high-sensitivity categories)

**Post-register**

1. Send verification email.
2. Create empty profile.
3. Register device.
4. Show onboarding: how matching and claiming work.

### 10.2 Login

- Email + password
- Optional biometric unlock of stored refresh token on device
- Optional phone OTP step-up when a new device is detected
- Admin login is **separate** (`/admin/login`) and always step-up with 2FA

### 10.3 Session model

| Client | Mechanism | Lifetime |
|---|---|---|
| Flutter | Sanctum token + refresh token in secure storage | Access 60 min, refresh 30 days, rotatable |
| Admin Inertia | Session cookie, `httpOnly`, `secure`, `sameSite=lax` | Idle 30 min, absolute 8–12 hours |
| Password reset | Signed, single-use link | 60 minutes |

### 10.4 Account settings (user)

- Edit display name, avatar, city
- Change email (re-verify)
- Change phone (OTP)
- Change password (require current)
- Active sessions / devices — revoke one or all
- Notification preferences
- Privacy: public profile stats on/off
- Download my data
- Deactivate account
- Delete account (grace period 14–30 days)

### 10.5 Verification levels

| Level | Meaning | Unlocks |
|---|---|---|
| L0 Guest | Not signed in | Teaser browse |
| L1 Registered | Email unverified | Browse only |
| L2 Email verified | Basic member | Create lost/found reports |
| L3 Phone verified | Trusted contact | Submit claims, open chat |
| L4 ID verified | High trust (manual or KYC vendor) | High-sensitivity items, hub pickup without extra staff quiz (still in-person check) |

### 10.6 Admin account operations

- Create staff users
- Assign roles per hub
- Force logout
- Reset 2FA
- Restrict / suspend / ban with reason
- Merge duplicate accounts (super admin, audited)
- Handle data-deletion requests

### 10.7 Account recovery

1. Email reset link (default)
2. Phone OTP if email is inaccessible and phone is verified
3. Support ticket + identity checks for locked accounts
4. Never reset via in-app chat with a “moderator”

---

## 11. End-to-end user journeys

### 11.1 I lost something

1. Open app → Home.
2. Tap **Report lost**.
3. Choose category → guided form → photos → last-seen map → hidden marks.
4. Submit. Status `under_review` if photos/category are sensitive, else auto-`published`.
5. Matching job runs. User gets “Possible matches”.
6. User opens a found teaser, starts a claim, answers challenges.
7. Finder or hub reviews. Chat opens if approved (or earlier if policy allows).
8. Book hub pickup or confirm meetup.
9. Both parties confirm handover. Case `recovered`.

### 11.2 I found something

1. Tap **Report found**.
2. Photo-first (modern Flutter pattern): snap → category suggestion → complete form.
3. Choose custody: keep it / drop at hub.
4. Submit. Public sees a teaser only.
5. Owner matches and claims.
6. Finder reviews answers. Approves or asks for more info.
7. Handover. Finder marked as “Returned an item”.

### 11.3 Hub intake

1. Staff signs in (hub role).
2. Hub home shows today’s intake queue and pickup appointments.
3. New found item → storage code printed / written → shelf.
4. System matches against nearby lost reports.
5. Owner claims → appointment → in-person verification → handover.

### 11.4 Dispute

1. Two claims on one found item.
2. Item locked (`claim_in_progress` / `disputed`).
3. Moderator compares answers + evidence.
4. One claim approved, others rejected with reason.
5. Audit log records the decision.

### 11.5 Admin moderation

1. New listing lands in Review queue if auto-rules fire (ID photos, vehicle, high-value jewelry).
2. Moderator approves, redacts, or rejects.
3. Flags appear in Abuse queue.
4. Repeat offenders get restricted automatically after N upheld flags (configurable).

---

## 12. Matching engine (detail)

### 12.1 v1 scoring (deterministic)

Start at 0. Add:

| Signal | Points (example) |
|---|---|
| Same category | +40 |
| Same subcategory / type attribute | +15 |
| Color overlap | +10 |
| Brand / model overlap | +15 |
| Date windows compatible | +10 |
| Distance < 1 km | +15 |
| Distance < 5 km | +8 |
| Same hub catchment | +10 |
| Shared uncommon keyword (serial fragment, engraving token) | +20 |
| Lost date clearly before found date | −25 |
| Category mismatch | discard |

Notify when score ≥ 60. Show “possible” from 40–59 inside the item’s Matches tab only.

### 12.2 Hard filters

- Different cities beyond max radius (config)
- Closed / expired / recovered items
- Banned users
- Highly sensitive categories require moderator to release matches

### 12.3 v2 (later)

- Vector similarity on description
- Image embedding similarity (careful: can leak lookalikes and increase false confidence)
- Learning-to-rank from accepted/rejected matches

---

## 13. API surface (v1)

Base: `/api/v1`  
Auth: `Authorization: Bearer {token}`  
Locale: `Accept-Language`  
Idempotency: `Idempotency-Key` on POST claim / handover

### 13.1 Auth

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/register` | Create user |
| POST | `/auth/login` | Issue tokens |
| POST | `/auth/refresh` | Rotate refresh |
| POST | `/auth/logout` | Revoke current |
| POST | `/auth/forgot-password` | |
| POST | `/auth/reset-password` | |
| POST | `/auth/email/verify` | |
| POST | `/auth/phone/otp/send` | Rate limited |
| POST | `/auth/phone/otp/confirm` | |

### 13.2 Me / devices / preferences

| Method | Path |
|---|---|
| GET/PATCH | `/me` |
| GET | `/me/devices` |
| DELETE | `/me/devices/{id}` |
| GET/PATCH | `/me/notification-preferences` |
| POST | `/me/data-export` |
| POST | `/me/deactivate` |
| POST | `/me/delete` |

### 13.3 Catalog

| Method | Path |
|---|---|
| GET | `/categories` |
| GET | `/hubs` |
| GET | `/hubs/{id}` |
| GET | `/cms/{slug}` |

### 13.4 Reports

| Method | Path |
|---|---|
| GET | `/reports` |
| POST | `/reports` |
| GET | `/reports/{id}` |
| PATCH | `/reports/{id}` |
| POST | `/reports/{id}/submit` |
| POST | `/reports/{id}/close` |
| GET | `/reports/{id}/matches` |
| POST | `/reports/{id}/media` |

Public show payload is a **teaser DTO**. Full DTO only for owner, approved claimant, hub staff, or admin.

### 13.5 Claims, chat, handover

| Method | Path |
|---|---|
| POST | `/claims` |
| GET | `/claims/{id}` |
| POST | `/claims/{id}/answers` |
| POST | `/claims/{id}/evidence` |
| POST | `/claims/{id}/withdraw` |
| GET | `/conversations` |
| GET | `/conversations/{id}/messages` |
| POST | `/conversations/{id}/messages` |
| POST | `/handovers` |
| POST | `/handovers/{id}/confirm` |

### 13.6 Other

| Method | Path |
|---|---|
| GET | `/notifications` |
| POST | `/notifications/{id}/read` |
| POST | `/flags` |
| GET | `/search` |

Admin Inertia uses web routes under `/admin/*`, not this mobile API. Staff who work in Flutter hub mode use API routes gated by `hub_staff` permissions.

---

## 14. Admin backend (Laravel + Inertia) — all screens

Admin lives at `/admin`. Layout: left nav, top bar (search, notifications, user), main canvas. Vue 3 pages in `resources/js/Pages/Admin/...`.

### 14.1 Information architecture

```
Admin
├── Auth
│   ├── Login
│   ├── Two-factor challenge
│   ├── Forgot password
│   └── Reset password
├── Dashboard
├── Review queues
│   ├── Listings review
│   ├── Claims review
│   ├── Abuse flags
│   ├── Disputes
│   └── Chat escalations
├── Directory
│   ├── Lost reports
│   ├── Found reports
│   ├── Matches
│   ├── Claims
│   └── Handovers
├── People
│   ├── Users
│   ├── User detail
│   ├── Roles & permissions
│   └── Staff invites
├── Network
│   ├── Hubs
│   ├── Hub detail / staff / storage
│   └── Categories & attributes
├── Communications
│   ├── Notifications composer
│   ├── Email/SMS logs
│   └── CMS pages
├── Insights
│   ├── Analytics
│   ├── Exports
│   └── Audit log
└── System
    ├── Settings
    ├── Feature flags
    ├── Jobs / Horizon link
    └── Maintenance banner
```

### 14.2 Screen-by-screen

#### A0 — Admin Login

- Email, password, remember, forgot link
- Lockout after N failures
- IP + user-agent logged

#### A1 — Two-factor challenge

- TOTP code
- Recovery codes
- New-device email alert

#### A2 — Dashboard

Widgets:

- Open lost / found counts
- Items awaiting review
- Claims awaiting decision
- Returns last 7 / 30 days
- Flags unreviewed
- Hub occupancy (items stored vs capacity)
- Funnel snapshot
- Moderator personal queue (“My next 10”)

#### A3 — Listings review queue

Table: thumbnail, type, category, area, reporter trust, auto-rule hits, age.  
Actions: open, approve, reject, request changes, redact photo, assign to me.

#### A4 — Listing detail (moderation)

- Full private fields
- Photo lightbox + EXIF-stripped badge
- Map
- Match candidates
- Claims
- Reporter profile
- Activity timeline
- Decision panel with required reason

#### A5 — Lost reports index

Filters: status, category, date, hub catchment, user, q.  
Bulk: expire, assign, export (permissioned).

#### A6 — Found reports index

Same as A5 plus custody, storage code, hub.

#### A7 — Matches index

Lost ↔ found pairs, score, status (`suggested`, `notified`, `accepted`, `dismissed`, `admin_forced`).  
Action: force-notify, dismiss as poor match.

#### A8 — Claims review queue

SLA timer, sensitivity badge, attempt count.

#### A9 — Claim detail

- Challenge answers vs hidden truth (side-by-side, permissioned)
- Evidence gallery
- Decision: approve / reject / request info
- Linked conversation
- Dispute banner if multiple claims

#### A10 — Handovers index / detail

Appointments calendar (simple list + date filter in v1), confirmation codes (hashed at rest; reveal once), completion status.

#### A11 — Abuse flags queue

Flag reason, target, reporter, severity, status.

#### A12 — Dispute detail

Both claims, evidence, recommended winner, resolution notes, notify parties.

#### A13 — Chat escalations

Read-only thread viewer for flagged conversations. Warn banner: “Access is audited.”

#### A14 — Users index

Search email/phone/name, role, status, trust.

#### A15 — User detail

- Profile and verification
- Devices and sessions (revoke)
- Reports, claims, flags
- Notes (internal)
- Actions: restrict, suspend, ban, verify phone manually, reset 2FA (staff only)

#### A16 — Roles & permissions

Matrix UI. Seeded permissions such as `reports.view_hidden`, `claims.decide`, `chat.read_flagged`, `users.ban`, `settings.manage`.

#### A17 — Staff invites

Invite by email + role + optional hub scope.

#### A18 — Hubs index / create / edit

Map picker, hours, visibility, retention defaults.

#### A19 — Hub detail

Staff list, storage locations, current inventory, pickup calendar, hub analytics.

#### A20 — Categories & attributes

Tree + drag order. Attribute editor: type (`text`, `color`, `enum`, `number`), visibility (`public`, `hidden_challenge`, `admin_only`), required flag.

#### A21 — Notification composer

Audience (all, city, hub, role), channels, schedule, preview.

#### A22 — Message delivery logs

Email/SMS/push status for support debugging. Mask recipients for non-admins.

#### A23 — CMS pages

Edit legal and help content. Publish / unpublish. Version history.

#### A24 — Analytics

Charts for Section M17. Date range, hub filter, category filter.

#### A25 — Exports

Request-based: job builds CSV, admin downloads once, expiry 24h, audit row.

#### A26 — Audit log

Filter by actor, subject, action, date. Immutable UI (no edit).

#### A27 — Settings

Grouped: general, auth, matching, claims, media, retention, maps, mail, SMS, push.

#### A28 — Feature flags

Toggle Phase-2 modules safely.

#### A29 — Maintenance

Banner text, read-only mode (block new reports/claims).

#### A30 — Admin account / 2FA setup

Current staff user’s security page.

#### A31 — Not found / forbidden / error

Inertia error pages that do not leak stack traces.

---

## 15. Flutter mobile — all screens

Visual language: modern Material 3, large photography, calm trust colors, plenty of whitespace, bottom navigation for primary tasks, prominent **Report** action. Dark mode supported from v1.

### 15.1 Navigation

**Guest / user bottom nav**

1. Home
2. Search
3. Report (center FAB)
4. Activity (matches, claims, chats badge)
5. Profile

**Hub staff extra tab or mode switch:** Hub desk

### 15.2 Screen inventory

#### Onboarding & auth

| ID | Screen | Purpose |
|---|---|---|
| F00 | Splash | Brand, token bootstrap, force-update check |
| F01 | Onboarding (3–4 pages) | Lost, found, verify, safe return |
| F02 | Welcome / auth picker | Log in, create account, browse as guest |
| F03 | Register | Form + terms |
| F04 | Login | Email/password, biometric if enrolled |
| F05 | Forgot password | Email request |
| F06 | Reset password | New password |
| F07 | Verify email | Deep link + manual code |
| F08 | Phone OTP send / confirm | Step-up |
| F09 | Profile setup | Display name, city, avatar |
| F10 | Permission primer | Camera, location, notifications (explain first) |

#### Home & discovery

| ID | Screen | Purpose |
|---|---|---|
| F11 | Home | Personalized: my open cases, nearby teasers, safety tip, hub near you |
| F12 | Search | Query + filters sheet |
| F13 | Search results | Mixed lost/found teasers |
| F14 | Map explore | Clustered teasers, no exact pins for others’ items |
| F15 | Category browse | Visual category grid |
| F16 | Hub list / map | Find a drop-off desk |
| F17 | Hub profile | Hours, directions, what they store |

#### Reports

| ID | Screen | Purpose |
|---|---|---|
| F18 | Report chooser | Lost vs Found, large cards |
| F19 | Lost — category | |
| F20 | Lost — details | Dynamic attributes from API schema |
| F21 | Lost — hidden marks | Serial, contents, “only used to verify you” copy |
| F22 | Lost — location & time | Map + date range |
| F23 | Lost — photos | Capture / gallery, guidance overlay |
| F24 | Lost — review & submit | Teaser preview vs private preview |
| F25 | Found — photo first | Camera-led |
| F26 | Found — details | |
| F27 | Found — custody | Keep vs hub drop-off |
| F28 | Found — review & submit | Reminder: don’t post ID numbers |
| F29 | Drafts | Resume incomplete reports |
| F30 | My reports | Tabs: active, recovered, closed |
| F31 | Report detail (owner) | Full data, matches, claims, share teaser link |
| F32 | Public teaser detail | Redacted card, CTA Claim or “I found something similar” |
| F33 | Close / expire reason | |

#### Matching, claims, recovery

| ID | Screen | Purpose |
|---|---|---|
| F34 | Matches list | For one report or global Activity |
| F35 | Match comparison | Side-by-side teaser vs my report (no hidden leak) |
| F36 | Start claim | Explain rules and attempt limits |
| F37 | Challenge questions | One question per screen, progress |
| F38 | Claim evidence upload | |
| F39 | Claim submitted | Waiting state |
| F40 | Claim detail | Status timeline |
| F41 | Review incoming claim (finder/hub) | Answers + decide |
| F42 | Request more info | |
| F43 | Handover setup | Type, time, place |
| F44 | Handover confirmation | Code + dual confirm |
| F45 | Recovery success | Share / thank-you (no forced social) |

#### Messaging & activity

| ID | Screen | Purpose |
|---|---|---|
| F46 | Inbox (chats) | |
| F47 | Conversation | Text + images, safety banner |
| F48 | Notifications | |
| F49 | Activity hub | Matches, claims, pickups in one feed |

#### Profile & settings

| ID | Screen | Purpose |
|---|---|---|
| F50 | Profile | Trust badges, my stats |
| F51 | Edit profile | |
| F52 | Settings | Grouped |
| F53 | Security | Password, 2FA/OTP, devices |
| F54 | Notification preferences | |
| F55 | Privacy | |
| F56 | Download my data | |
| F57 | Deactivate / delete | Strong confirm |
| F58 | Help center | CMS-driven |
| F59 | Article detail | |
| F60 | Contact support | Ticket form |
| F61 | Legal (terms, privacy, guidelines) | |
| F62 | About / version | |

#### Hub staff mode

| ID | Screen | Purpose |
|---|---|---|
| F63 | Hub home | Intake today, pickups today, stored count |
| F64 | New intake | Fast found-item form + storage code |
| F65 | Storage inventory | Search by code / category |
| F66 | Pickup appointment detail | Verify owner in person |
| F67 | Hub scan (Phase 2) | QR on tag or storage label |

#### System / edge

| ID | Screen | Purpose |
|---|---|---|
| F68 | Empty states | Per list |
| F69 | Offline / retry | Queue drafts |
| F70 | Force update | |
| F71 | Maintenance | |
| F72 | 403 / banned | |
| F73 | Image lightbox | |
| F74 | Report / flag sheet | |
| F75 | Block user confirm | |

### 15.3 Flutter UX notes (modern look)

- Use a **photo-forward** home: large teaser cards, 16:9 media, category chips.
- Center FAB for Report; never bury it.
- Progress stepper on multi-step report forms.
- Skeleton loaders, not blank spinners.
- Haptics on claim submit and handover confirm.
- Accessibility: Dynamic Type, contrast, screen-reader labels on all icon buttons.
- Trust microcopy on every hidden-field screen.

---

## 16. Security

Security is a product feature. Lost-and-found apps are attractive to scammers and identity thieves.

### 16.1 Threat model (summary)

| Threat | Mitigation |
|---|---|
| Fake owner claims an item | Hidden challenges, attempt limits, evidence, hub in-person check |
| Scraper harvests listings | Teasers only, rate limits, no exact pins, bot detection |
| Finder fishes for ID data | Never show serials/ID photos publicly |
| Account takeover | Strong passwords, device alerts, step-up OTP, admin 2FA |
| Staff misuse | Roles, audited access to chats and hidden fields |
| Malicious uploads | Type/size checks, EXIF strip, later AV scan |
| Unsafe meetup | Prefer hubs, safety tips, report button |
| Enumeration of emails/phones | Generic auth responses, rate limits |
| Token theft | Short-lived access tokens, refresh rotation, secure storage |
| Privilege escalation | Policies on every action, no client-supplied roles |

### 16.2 Application security

- Laravel policies for every report, claim, message, and media object
- Mass-assignment protection; explicit DTOs / Form Requests
- CSRF on all Inertia/session routes
- Sanctum tokens for mobile; revoke on password change
- Rate limiting: login, OTP, search, claim submit, message send
- Signed temporary URLs for private media
- Hidden fields never included in public JSON (automated tests)
- Admin routes on separate path + middleware (`role:moderator|admin|...`)
- Security headers: HSTS, frame deny, referrer policy, CSP for admin
- CORS allowlist for known app origins only

### 16.3 Data protection

- Passwords hashed with bcrypt/argon2
- Refresh tokens hashed at rest
- Handover codes hashed
- Phone/email searchable via index, displayed masked in admin lists
- ID documents: view once during review, then delete binary; keep “verified/rejected” status
- Encryption at rest for highly sensitive columns if required by jurisdiction (IDs, exact card numbers — better: **do not store full card numbers at all**)
- Separate S3 prefixes: `public-teasers/` vs `private-evidence/`

### 16.4 Privacy by design

- Default listing visibility: match-only for documents and IDs
- Coarse location for public maps
- Chat until trust is established
- Data export and deletion (GDPR-style), even if you launch in one country
- Clear retention: example 90 days after recovery, longer if disputed or legally held

### 16.5 Abuse and safety

- Auto-flag listings whose photos look like passports / credit cards (classifier or simple heuristics + moderator)
- Keyword lists for meetup-off-platform + payment scams in chat
- User block
- Graduated enforcement: warn → restrict → suspend → ban
- Child-safety: no category for missing persons; this is **items only**. Missing-person reports are rejected and pointed to authorities.

### 16.6 Operational security

- Secrets in `.env`, never in the Flutter app (maps key via proxy if needed)
- Admin 2FA mandatory
- Staging data is anonymized
- Backups encrypted; restore tested
- Least-privilege DB and bucket IAM
- Dependency updates (Composer, pub) on a schedule

### 16.7 Testing security

Must-have automated tests:

- Public show endpoint cannot return `serial`, `hidden_notes`, exact coordinates
- User A cannot PATCH user B’s report
- Guest cannot create claims
- L2 user cannot claim without phone (if policy on)
- Moderator chat access writes audit log
- Claim challenge answers are not echoed back to the claimant after submit

---

## 17. Optimization

### 17.1 Backend performance

- Eager-load relations; no N+1 on admin tables (Inertia props pagination)
- Pagination everywhere (cursor for feeds, page for admin)
- Cache categories, CMS, settings, hub list (`Cache::remember`)
- Redis for sessions (prod), cache, locks (`lock:match:{id}`)
- Matching and image variants **always queued**
- Scout/Meilisearch for search; MySQL is not the long-term search engine
- Database indexes listed in §9.4
- Horizon for queue visibility; alert on growing queues
- Read replicas only when metrics say so (not v1)

### 17.2 Media performance

- Client-side compression (max edge 1600px, JPEG/WebP ~70–80%)
- Responsive variants
- CDN + immutable cache headers for public teasers
- Lazy load admin galleries
- Signed URLs expire quickly for private evidence

### 17.3 Flutter performance

- `ListView.builder` / slivers; no huge unbounded lists
- `cached_network_image` + memory cache cap
- Isolate or compute for image compress
- Debounced search (300–400ms)
- Pagination + pull-to-refresh
- Offline draft persistence so a lost connection does not destroy a 6-step form
- Impeller-friendly UI (avoid excessive saveLayer / giant blur)
- Split codegen / lazy routes if startup grows
- Crash and ANR monitoring (Firebase Crashlytics or Sentry)

### 17.4 Matching performance

- Geohash prefix filter before scoring
- Category prefilter
- Cap candidates (top 20 stored, top 5 notified)
- Idempotent jobs; debounce updates (5 minutes) so photo uploads do not thrash

### 17.5 Admin UX performance

- Server-side filtered tables
- Deferred Inertia props for heavy widgets (charts)
- Don’t load full chat history on dashboard

### 17.6 Cost control

- Queue workers sized to photo volume
- Lifecycle rules: delete unused drafts and expired private media
- Push over SMS except OTP
- Thumbnails, not originals, in lists

---

## 18. Notifications matrix

| Event | In-app | Push | Email | SMS |
|---|---|---|---|---|
| Verify email | | | Yes | |
| Verify phone | | | | Yes |
| Password changed | Yes | Yes | Yes | |
| New device login | Yes | Yes | Yes | |
| Report approved/rejected | Yes | Yes | Yes | |
| New match | Yes | Yes | Optional | |
| Claim received | Yes | Yes | Yes | |
| Claim decision | Yes | Yes | Yes | Optional |
| New chat message | Yes | Yes | | |
| Handover reminder | Yes | Yes | Yes | Optional |
| Expiry warning | Yes | Yes | Yes | |
| Admin broadcast | Yes | Optional | Optional | |

---

## 19. Permissions (seed list)

```
users.view
users.update_status
users.assign_roles
reports.view
reports.view_hidden
reports.moderate
reports.force_status
matches.view
matches.force
claims.view
claims.view_answers
claims.decide
handovers.view
handovers.manage
chat.read_flagged
flags.manage
disputes.manage
hubs.manage
categories.manage
cms.manage
notifications.compose
analytics.view
exports.create
audit.view
settings.manage
```

Hub-scoped permissions resolve against `hub_id` on the staff assignment.

---

## 20. Non-functional requirements

| Area | Requirement |
|---|---|
| Availability | 99.5% monthly for API (v1 commercial target) |
| API p95 | < 300ms for reads excluding search; search < 500ms |
| Upload | 6 images, ≤ 8MB each before client compress; reject larger |
| Offline | Drafts and “sent” queue for messages when possible |
| i18n | English v1; all strings through lang files / Flutter ARB |
| a11y | WCAG 2.2 AA for admin; Flutter semantics on all controls |
| Support | Android 8+ / iOS 15+ |
| Browsers (admin) | Last two Chrome, Edge, Firefox, Safari versions |

---

## 21. Legal and policy (product-level)

This is not legal advice. Before launch, a lawyer should review:

- Terms of use (no guarantee of return; users act in good faith)
- Privacy policy (what you store, matching, chat access, retention)
- Community guidelines
- Hub data-processing agreement if campuses/malls join
- Local rules for found property (some cities require police handoff after N days)
- Prohibited items: weapons, illegal drugs, human remains, live animals as “lost pets” may need a specialist path
- This platform is **not** a missing-person or law-enforcement database

Build a **Found property policy** per hub: retention days, police transfer, disposal.

---

## 22. Testing strategy

### 22.1 Backend

- Feature tests for auth, policies, teaser DTO, claim attempts, matching job
- Policy tests per role
- Queue fakes for notifications
- Pest or PHPUnit

### 22.2 Admin (Inertia)

- Laravel HTTP tests asserting Inertia component names + props
- A few browser tests (Dusk or Playwright) for login + review decision

### 22.3 Flutter

- Widget tests for report stepper and claim questions
- Golden tests for key cards (home, teaser, claim)
- Integration test: login → create lost draft → submit (mock API)

### 22.4 Manual / UAT

- Owner/finder happy path
- Hub intake + pickup
- Double claim dispute
- Banned user
- Guest vs L1 vs L3 permissions
- Airplane-mode draft resume

---

## 23. Folder / repo layout (recommended)

Monorepo is optional. Two repos is also fine.

```
lostandfound/
├── DOCUMENTATION.md          ← this file
├── backend/                  ← Laravel + Inertia
│   ├── app/Domain/...
│   ├── app/Http/Controllers/Admin
│   ├── app/Http/Controllers/Api/V1
│   ├── resources/js/Pages/Admin
│   └── tests/
└── mobile/                   ← Flutter
    ├── lib/features/auth
    ├── lib/features/home
    ├── lib/features/reports
    ├── lib/features/claims
    ├── lib/features/chat
    ├── lib/features/hub
    └── lib/features/profile
```

Implement Laravel as a **modular domain** (`app/Domain/Reports`, `Claims`, `Matching`, …) rather than fat controllers.

---

## 24. Phased delivery

### Phase 0 — Foundations (week 1–2)

- Laravel project, Inertia admin shell, auth, roles
- Flutter project, design tokens, auth screens, API client
- Users, categories, basic settings
- CI for both

### Phase 1 — MVP (the smallest useful product)

- Lost + found reports with media
- Public teasers + search
- Deterministic matching job
- Claims with hidden-field challenges
- In-app chat after claim submit
- Hub CRUD + staff intake
- Admin: review listings, decide claims, users, audit log
- Push + email for match/claim

**MVP is successful when** a finder and an owner can complete a return through a hub without exchanging phone numbers.

### Phase 1.5

- Meilisearch
- Redis + Horizon
- Phone OTP
- Map explore
- Notification preferences
- CMS

### Phase 2

- QR tags
- ID verification
- Public web teasers
- Tips / payments (if approved)
- Image moderation assist
- i18n
- Reputation

### Phase 3

- Partner SSO
- Multi-city / multi-tenant organizations
- Advanced matching
- Official police/municipal integrations where lawful

---

## 25. Implementation checklist (MVP)

### Backend

- [ ] Laravel 11 + Breeze/Fortify Inertia Vue
- [ ] Sanctum token auth for Flutter
- [ ] Spatie Permission + seeded roles
- [ ] Categories + dynamic form schema endpoint
- [ ] Item reports CRUD + status machine
- [ ] Media upload + EXIF strip + variants
- [ ] Teaser vs private serializers + tests
- [ ] Match job + notify
- [ ] Claims + attempt limits
- [ ] Conversations
- [ ] Hubs + storage codes
- [ ] Flags
- [ ] Admin pages A0–A15, A18–A20, A26–A27 minimum
- [ ] Audit log
- [ ] Rate limits
- [ ] OpenAPI draft

### Flutter

- [ ] Design system (colors, type, cards, buttons, inputs)
- [ ] F00–F10 auth/onboarding
- [ ] F11–F17 discovery
- [ ] F18–F33 reports
- [ ] F34–F45 claims/handover
- [ ] F46–F49 activity
- [ ] F50–F62 profile/help
- [ ] F63–F66 hub mode
- [ ] Push handling
- [ ] Draft persistence
- [ ] Deep links (verify email, teaser)

---

## 26. Open decisions (resolve before build)

| Topic | Options | Recommendation |
|---|---|---|
| Inertia frontend | Vue 3 vs React | **Vue 3 + TS** (Laravel ecosystem default) |
| State (Flutter) | Riverpod vs Bloc | **Riverpod** |
| Search v1 | MySQL vs Meilisearch | MySQL for first slice, Scout interface so you can swap |
| Chat timing | After claim submit vs after approval | **After claim submit**, with extra redaction |
| Guest browse | On vs off | **On**, teasers only |
| Social login | Now vs later | **Later** (Phase 1.5) |
| Multi-country | Single country first | **Single country** until legal review |
| Payments | None in MVP | **None** |
| Product name | Reunite vs client brand | Keep working name Reunite until brand exists |

---

## 27. What “done” means for this specification

A future implementation is aligned with this document when:

1. Every M01–M20 module has an owner and a Laravel domain (or an explicit “won’t build in this phase”).
2. Every admin screen in §14 and Flutter screen in §15 is either built, explicitly deferred, or merged into another screen.
3. Public APIs cannot leak hidden ownership fields (proven by tests).
4. A lost report and a found report can match, claim, chat, and close via hub handover.
5. Admins can moderate listings, decide claims, and see an audit trail.
6. Performance work in §17 is not treated as optional polish; queues and pagination ship with MVP.

---

## 28. Next step after this document

When you are ready to build, the natural order is:

1. Scaffold Laravel + Inertia admin and Flutter app skeletons.
2. Lock the data model and OpenAPI for `/api/v1`.
3. Implement accounts (M01) on both clients.
4. Implement reports + media + teasers.
5. Add matching, claims, chat, hubs, then admin queues.

This specification is complete enough to start Phase 0 without another discovery pass, unless you want to change product name, country, or the Vue-vs-React admin choice.
