.PHONY: app bash

# Run from this directory (same folder as docker-compose.yml).

app:
	docker compose up --build --watch

bash:
	docker compose exec -it app bash
