# Development image: use with docker compose (bind-mount source + named deps/_build volumes).
FROM elixir:1.16-alpine

RUN apk add --no-cache build-base git bash

WORKDIR /app

ENV MIX_ENV=dev

COPY mix.exs ./

RUN mix local.hex --force && mix local.rebar --force && mix deps.get && mix deps.compile

COPY docker/entrypoint-dev.sh /entrypoint-dev.sh
RUN chmod +x /entrypoint-dev.sh

EXPOSE 4000

ENTRYPOINT ["/entrypoint-dev.sh"]
CMD ["mix", "phx.server"]
