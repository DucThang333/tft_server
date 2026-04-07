.PHONY: app sync-start bash

# Start sync daemon + stack (Phoenix code_reloader works reliably vs bind mount).
sync-start:
	docker-sync start

# One-off app container with docker-sync volume + IEx; Phoenix on http://localhost:4000 (matches tft/.env VITE_API_BASE_URL).
app: sync-start
	docker rm -f tft_running_app 2>/dev/null || true
	docker compose -f docker-compose.yml -f docker-compose.sync.yml run -it --name tft_running_app --rm -p 4000:4000 app iex -S mix phx.server

bash:
	docker compose exec -it app bash
