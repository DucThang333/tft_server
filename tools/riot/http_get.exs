#!/usr/bin/env elixir
# Standalone HTTPS GET with Riot X-Riot-Token header (no Mix project required).
#
# Usage (from repo tft_server/ or with paths adjusted):
#   RIOT_API_KEY=rgapi-... elixir tools/riot/http_get.exs \
#     "https://na1.api.riotgames.com/tft/status/v1/platform-data"
#
# Riot TFT API index: https://developer.riotgames.com/apis

Mix.install([
  {:req, "~> 0.5.0"},
  {:jason, "~> 1.4"}
])

[url] = System.argv()

if url == nil or url == "" do
  IO.puts(:stderr, "Usage: RIOT_API_KEY=... elixir tools/riot/http_get.exs <url>")
  System.halt(1)
end

api_key = System.get_env("RIOT_API_KEY")

if api_key == nil or api_key == "" do
  IO.puts(:stderr, "Set RIOT_API_KEY")
  System.halt(1)
end

case Req.get(url, headers: [{"X-Riot-Token", api_key}], decode_body: true) do
  {:ok, %{status: 200, body: body}} when is_map(body) ->
    IO.puts(Jason.encode!(body, pretty: true))

  {:ok, %{status: 200, body: body}} ->
    IO.puts(Jason.encode!(body, pretty: true))

  {:ok, %{status: status, body: body}} ->
    IO.puts(:stderr, "HTTP #{status}")
    IO.puts(Jason.encode!(body, pretty: true))
    System.halt(2)

  {:error, reason} ->
    IO.puts(:stderr, "Request failed: #{inspect(reason)}")
    System.halt(3)
end
