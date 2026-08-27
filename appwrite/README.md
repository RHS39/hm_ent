# Appwrite Setup — Hari Om Traders (hm_ent)

This folder provisions the full Appwrite backend.

**Database:** `hari_om_db`
**Collections:** `products`, `subscribers`, `contact_messages`
**Bucket:** `product-images` (public)

## 1) Quick Start (2 min) — Appwrite Cloud Console (recommended)

### A. Create Project
1. Go to https://cloud.appwrite.io
2. Create Project → e.g. `hari-om-traders` → note **Project ID** (Settings → General)

### B. Create Database
1. Console → **Databases** → **Create Database** → ID: `hari_om_db` , Name: `Hari Om DB`

### C. Create Collections — use the tables below (copy exact IDs/keys)
Create each via **Create Collection** with ID as listed.

#### `products` — ID: `products`
| key | type | required | extra |
|-----|------|----------|-------|
| product_id | string 32 | yes | — |
| name | string 128 | yes | — |
| price | double | yes | min 0 |
| description | string 1000 | no | default "" |
| icon | string 32 | no | default "spa" |
| category | string 32 | no | default "Jaggery" |
| stock_quantity | integer | no | default 100, min 0 |
| moq | integer | no | default 2, min 1, max 999 |
| image_url | string 500 | no | url |
| image_2 | string 500 | no | url |
| image_3 | string 500 | no | url |
| is_active | boolean | no | default true |

Indexes:
- `idx_product_id` unique on `product_id`
- `idx_name` unique on `name`
- `idx_category` key on `category`

Permissions: `documentSecurity: true`, затем для Collection:
- `read("any")` — public shop
- `create("users")`, `update("users")`, `delete("users")` — logged-in admin (or restrict to `team: admin` in prod)

#### `subscribers` — ID: `subscribers`
| key | type | required | default |
|-----|------|----------|---------|
| email | string 255 | yes | — |
| status | string 32 | yes | "active" |
| subscribed_at | datetime | yes | — |
| updated_at | datetime | yes | — |
| source | string 64 | no | "home_newsletter" |
| meta | string 2000 | no | "{}" |

Indexes: `idx_email` unique on `email`, `idx_status` key on `status`

Permissions: `create("any")` (newsletter form), `read("users")` (admin only)

#### `contact_messages` — ID: `contact_messages`
| key | type | required | default |
|-----|------|----------|---------|
| name | string 128 | yes | — |
| email | string 255 | yes | — |
| phone | string 32 | yes | — |
| address | string 500 | yes | — |
| pincode | string 16 | yes | — |
| district | string 64 | yes | — |
| state | string 64 | yes | — |
| country | string 64 | no | "India" |
| message | string 2000 | yes | — |
| source | string 64 | no | "contact_us_page" |
| status | string 32 | no | "new" |

Permissions: `create("any")`, `read("users")`

### D. Create Storage Bucket
1. **Storage** → Create Bucket → ID: `product-images`, Name: `Product Images`
2. Enable **Public** (so `getPublicUrl`/`view` works), Max 5 MB, Allowed: `jpg,jpeg,png,webp,gif`

### E. Auth
1. **Auth** → Settings → enable **Email/Password**
2. Create admin user: `admin@hariomtraders.com` / `HariOm@2026` (or use dummy-admin mode in app)

## 2) Wire Flutter App

Pass config via `--dart-define`:

```bash
flutter run \
  --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=APPWRITE_DATABASE_ID=hari_om_db \
  --dart-define=APPWRITE_PRODUCTS_COLLECTION_ID=products \
  --dart-define=APPWRITE_SUBSCRIBERS_COLLECTION_ID=subscribers \
  --dart-define=APPWRITE_CONTACT_COLLECTION_ID=contact_messages \
  --dart-define=APPWRITE_BUCKET_ID=product-images
```

For release, store in `lib/appwrite/appwrite_config.dart` defaultValue or CI secrets.

App init is already in `lib/main.dart` — `AppwriteService.init()` + `AppwriteAuthService.initListener()`.

## 3) Automated Setup (Alternative — Script)

If you have an **API Key** (Project → Settings → API Keys → create with scopes `databases.write`, `collections.write`, `attributes.write`, `indexes.write`, `buckets.write`):

```bash
# Set env
export APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
export APPWRITE_PROJECT_ID=xxx
export APPWRITE_API_KEY=xxx

# Using Appwrite CLI
npm i -g appwrite-cli
appwrite login --endpoint $APPWRITE_ENDPOINT  # or use apiKey
dart run appwrite/setup_appwrite.dart
```

See `setup_appwrite.dart` in this folder.

## 4) Seed Data

After DB creation, seed 15 demo jaggery products:

```dart
// In Dart code after AppwriteService.init():
await AppwriteProductRepository.seedDemoProducts();
```

Or call once from debug screen / `AppwriteExample` widget.

## 5) Verify

- `AppwriteService.isInitialized == true` in logs
- Visit Products page — data loads from Appwrite
- Test newsletter subscribe & contact form → check Appwrite Console → Databases → documents appear

## 6) Permissions Notes (Production Hardening)

Replace `users` with a team/role:
- Create Team `admin`, add admin users
- Change collection permissions to `read("team:admin")` / `create("team:admin")` etc.
- For public `products` read keep `any`, but write = `team:admin` only

---

Generated: 2026-05-11. Schema field names are Appwrite-compatible (snake_case preserved via `data` map).
