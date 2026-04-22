# Shortly — URL shortener with analytics

A small URL shortener that tracks per-link clicks over time. Built as a hands-on database learning project — SQL is raw (no ORM), and the project includes a migration from SQLite to PostgreSQL to surface the real differences between them.

## Features

- Shorten any `http(s)` URL to a 6-character code
- Redirect from `/:code` to the original URL
- Record every click with timestamp, referrer, and user-agent
- Per-URL stats page: total clicks, clicks by day, top referrers

## Tech stack

- **Node.js** + **Express 5** — backend
- **PostgreSQL** (hosted on [Neon](https://neon.tech)) — primary database
- **SQLite** (`better-sqlite3`) — used as the starting point; migration script copies data to Postgres
- Vanilla HTML / CSS / JS — frontend (no framework)

## Running locally

Prerequisites: Node 20+, a PostgreSQL connection string (Neon free tier works).

```bash
npm install
cp .env.example .env           # then edit .env and paste your DATABASE_URL
npm run migrate:pg             # create schema (+ copies any local urls.db data if present)
npm start                      # http://localhost:3000
```

## Running ad-hoc SQL

Query files live in `queries/`. Run any of them against your Postgres DB:

```bash
npm run sql -- queries/clicks_per_url.sql
```

## Project layout

```
├── db.js                    Postgres connection pool + schema init
├── server.js                Express routes (shorten, redirect, stats)
├── sql.js                   Tiny runner for ad-hoc .sql files
├── migrate-to-postgres.js   One-off: creates schema + copies SQLite → PG
├── queries/                 Example SQL files
└── public/                  Frontend (index.html, stats.html, script.js, ...)
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

## API

| Method | Path               | Description                                |
|--------|--------------------|--------------------------------------------|
| POST   | `/api/shorten`     | Body: `{ "url": "https://…" }` → short URL |
| GET    | `/api/stats/:code` | JSON stats for a short code                |
| GET    | `/:code`           | 302 redirect to the long URL               |
