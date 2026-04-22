# Shortly — URL shortener with analytics

A small URL shortener that tracks per-link clicks over time. Built as a hands-on database learning project — SQL is raw (no ORM), the project includes a migration from SQLite to PostgreSQL to surface the real differences between them, and ships with a web frontend **and** a Flutter mobile client both talking to the same API.

**Live demo:** https://url-shortener-mvzx.onrender.com
*(First request after idle may take ~30s on Render's free tier to spin up.)*

<p align="center">
  <img src="screenshots/mobile-home.png"     width="260" alt="Home screen — empty input field" />
  <img src="screenshots/mobile-loading.png"  width="260" alt="Shortening in progress" />
  <img src="screenshots/mobile-result.png"   width="260" alt="Short URL result with Copy and View stats actions" />
</p>

## Features

- Shorten any `http(s)` URL to a 6-character code
- Redirect from `/:code` to the original URL
- Record every click with timestamp, referrer, and user-agent
- Per-URL stats: total clicks, clicks by day, top referrers
- **Web UI** (served by the backend) and **Flutter app** (web/Android) — both hit the same JSON API

## Tech stack

**Backend**
- **Node.js** + **Express 5** — raw SQL, no ORM
- **PostgreSQL** on [Neon](https://neon.tech) (production) — started on **SQLite** and migrated, to learn the differences
- Deployed on [Render](https://render.com)

**Web frontend**
- Vanilla HTML / CSS / JS, served by the backend

**Mobile app** (`app/`)
- **Flutter** (Dart) — targets web + Android from one codebase
- Talks to the live backend over HTTPS

## Running the backend

Prerequisites: Node 20+, a PostgreSQL connection string (Neon free tier works).

```bash
npm install
cp .env.example .env           # edit .env and paste your DATABASE_URL
npm run migrate:pg             # create schema (+ copies any local urls.db data if present)
npm start                      # http://localhost:3000
```

## Running the Flutter app

Prerequisites: Flutter 3.19+.

```bash
cd app
flutter pub get
flutter run -d chrome          # fastest dev loop — opens in Chrome
# or:
flutter run                    # uses a connected Android device / emulator
```

The API base URL lives in [`app/lib/api.dart`](app/lib/api.dart) — point it at `http://localhost:3000` to run against a local backend, or leave it at the Render URL for the live one.

## Running ad-hoc SQL

Query files live in `queries/`. Run any of them against your Postgres DB:

```bash
npm run sql -- queries/clicks_per_url.sql
```

## Project layout

```
├── server.js                 Express routes (shorten, redirect, stats) + CORS, trust proxy
├── db.js                     Postgres connection pool + schema init
├── sql.js                    Tiny runner for ad-hoc .sql files
├── migrate-to-postgres.js    One-off: creates schema + copies SQLite → PG
├── queries/                  Example SQL files
├── public/                   Web frontend (index.html, stats.html, ...)
└── app/                      Flutter mobile client (web + Android)
    └── lib/
        ├── main.dart
        ├── home_screen.dart
        ├── stats_screen.dart
        └── api.dart
```

## Data model

```
urls                                clicks
────                                ──────
id          SERIAL PK              id          SERIAL PK
short_code  TEXT UNIQUE       ←─   url_id      INTEGER FK → urls(id)
long_url    TEXT                   clicked_at  TIMESTAMPTZ
created_at  TIMESTAMPTZ            referrer    TEXT
                                   user_agent  TEXT
```

Indexes:
- `urls.short_code` — implicit, from `UNIQUE`
- `idx_clicks_url_id` — stats queries filter by `url_id`
- `idx_clicks_clicked_at` — for time-range queries

Foreign keys are `ON DELETE CASCADE`, so deleting a URL drops its clicks atomically.

## API

| Method | Path               | Description                                |
|--------|--------------------|--------------------------------------------|
| POST   | `/api/shorten`     | Body: `{ "url": "https://…" }` → short URL |
| GET    | `/api/stats/:code` | JSON stats for a short code                |
| GET    | `/:code`           | 302 redirect to the long URL               |

CORS is enabled (`*`) so the same API can serve any frontend you point at it.
