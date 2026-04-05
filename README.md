# tft_server

Phoenix JSON API for the TFT Mystic Archive frontend in `../tft`.

## Requirements

- Elixir 1.14+ and Erlang/OTP 26+
- PostgreSQL 14+ (or Docker — see below)

## Docker

From `tft_server/`:

- **Dev database**: `tft` (`POSTGRES_DB`)
- **Test database**: `tft_test` (created on first volume init by `docker/postgres/init-databases.sql`)

### PostgreSQL only (API on the host)

```bash
docker compose up -d db
```

Then on the host: `mix ecto.migrate`, `mix run priv/repo/seeds.exs`, `mix phx.server` (uses `DATABASE_HOST` unset → `localhost`).

### Phoenix app + Postgres in Docker (live code reload)

The `app` service bind-mounts the project into the container and keeps `deps` / `_build` in named volumes (Linux-compiled artifacts). `config/dev.exs` sets `code_reloader: true`, so edits under `lib/` (and other compiled paths) are picked up without restarting the container.

```bash
docker compose up --build --watch
```

Shortcuts (from `tft_server/`): `make app` (same as above) and `make bash` (interactive shell in the `app` container; start the stack first).

`--watch` needs Docker Compose **v2.22+**. It rebuilds the `app` image when `mix.exs`, `Dockerfile`, or `docker/entrypoint-dev.sh` change.

First time (or after `docker compose down -v`), apply schema and seeds inside the container:

```bash
docker compose exec app mix ecto.migrate
docker compose exec app mix run priv/repo/seeds.exs
```

API: `http://127.0.0.1:4000`. The app connects to Postgres with `DATABASE_HOST=db` on the Compose network.

Detached run without watch:

```bash
docker compose up --build -d
```

Stop without removing data: `docker compose down`. Wipe DB volume and re-run init scripts on next start: `docker compose down -v`.

## Setup (without Docker)

```bash
cd tft_server
mix deps.get
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

Run the API (defaults to `http://127.0.0.1:4000`):

```bash
mix phx.server
```

## API (v1)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/health` | Liveness |
| GET | `/api/v1/champions` | Champion roster (camelCase JSON; mỗi tướng có `augmentState`, `encounters`) |
| POST | `/api/v1/admin/champions` | Tạo tướng — body `{ "champion": { ... } }` (camelCase). `augmentState`: `{ "linked": [ { "id", "tier", ... } ], "notes" }` (trạng thái lõi). `encounters`: mảng kỳ ngộ (`id`, `name`, `description`, `imageUrl`, …). |
| PUT | `/api/v1/admin/champions/:id` | Cập nhật một phần — chỉ các field gửi trong `champion` mới được đổi (vd. chỉ `augmentState` hoặc `encounters`). |
| GET | `/api/v1/items/base` | Base items |
| GET | `/api/v1/items/combined` | Combined items |
| GET | `/api/v1/meta/compositions` | Meta compositions |
| GET | `/api/v1/meta/overview` | Region / patch label / “updated” display |
| GET | `/api/v1/board/bootstrap` | Synergies, board, tray, item strip |
| GET | `/api/v1/riot/platform-status` | Latest stored Riot `tft/status/v1/platform-data` JSON (optional `?platform=na1`) |

CORS is enabled for browser dev (`*`).

## Riot Games TFT API (ingest)

Official API index: [developer.riotgames.com/apis](https://developer.riotgames.com/apis) (TFT: `tft-status-v1`, `tft-match-v1`, `tft-league-v1`, `spectator-tft-v5`, etc.).

1. Create a key in the Riot developer portal and export **`RIOT_API_KEY`** (never commit it).
2. Optional defaults: **`RIOT_PLATFORM`** (e.g. `na1`, `euw1`) and **`RIOT_REGION`** (e.g. `americas`, `europe` for match routes) — see `config/dev.exs` `:riot`.
3. Migrate DB: `mix ecto.migrate` (adds `riot_snapshots` for raw JSON).
4. Pull data over HTTPS and persist:

```bash
RIOT_API_KEY=rgapi-... mix tft.riot.pull_status --platform na1
RIOT_API_KEY=rgapi-... mix tft.riot.pull_match --region americas --id NA1_...
RIOT_API_KEY=rgapi-... mix tft.riot.pull_match_ids --region americas --puuid <PUUID>
```

5. Standalone GET helper (no Mix project): `elixir tools/riot/http_get.exs "https://na1.api.riotgames.com/tft/status/v1/platform-data"`

Snapshots are stored as JSONB for later ETL into your game catalog tables (`champions`, `compositions`, etc.); the client in `lib/tft_server/riot/client.ex` is the shared HTTPS layer.

## Tests

Ensure PostgreSQL is running (e.g. `docker compose up -d`) and credentials in `config/test.exs` match (`tft_test` database), then:

```bash
mix test
```

## Frontend integration

The Vite app in `../tft` loads all roster/meta/board data from this API (`src/api/tftApi.ts`). In dev, `vite.config.ts` proxies `/api` to `http://127.0.0.1:4000`, so run `mix phx.server` (or `make app`) and `npm run dev` together. Override the base URL with env `VITE_API_BASE_URL` if the API is on another origin.

## Configuration

- **Dev DB**: `tft` (see `config/dev.exs`).
- **Test DB**: `tft_test` plus optional `MIX_TEST_PARTITION` suffix (see `config/test.exs`).
- **Prod**: set `DATABASE_URL` and `SECRET_KEY_BASE` (see `config/runtime.exs`).
