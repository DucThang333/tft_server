defmodule TftServer.Riot.Client do
  @moduledoc """
  HTTPS client for [Riot Games APIs](https://developer.riotgames.com/apis).

  TFT-related products include `tft-status-v1`, `tft-match-v1`, `tft-league-v1`,
  `spectator-tft-v5`, and `tft-summoner-v1` (RSO).

  All requests send `X-Riot-Token` with your development API key from the portal.
  """

  @doc """
  TFT Status v1 — platform routing.

  `GET https://{platform}.api.riotgames.com/tft/status/v1/platform-data`

  `platform` examples: `na1`, `euw1`, `kr`, `jp1`.
  """
  def tft_platform_data(api_key, platform) when is_binary(api_key) and is_binary(platform) do
    url = "https://#{platform}.api.riotgames.com/tft/status/v1/platform-data"
    get_json(api_key, url)
  end

  @doc """
  TFT Match v1 — regional routing.

  `GET https://{region}.api.riotgames.com/tft/match/v1/matches/{matchId}`

  `region` examples: `americas`, `europe`, `asia`, `sea`.
  """
  def tft_match(api_key, region, match_id)
      when is_binary(api_key) and is_binary(region) and is_binary(match_id) do
    url = "https://#{region}.api.riotgames.com/tft/match/v1/matches/#{match_id}"
    get_json(api_key, url)
  end

  @doc """
  TFT Match v1 — match ID list for a PUUID.

  Query opts: `start`, `count` (see Riot docs).
  """
  def tft_match_ids_by_puuid(api_key, region, puuid, opts \\ [])
      when is_binary(api_key) and is_binary(region) and is_binary(puuid) do
    start = Keyword.get(opts, :start, 0)
    count = Keyword.get(opts, :count, 20)
    query = URI.encode_query(%{"start" => start, "count" => count})

    url =
      "https://#{region}.api.riotgames.com/tft/match/v1/matches/by-puuid/#{puuid}/ids?#{query}"

    get_json(api_key, url)
  end

  defp get_json(api_key, url) do
    case Req.get(url,
           headers: [{"X-Riot-Token", api_key}],
           decode_body: true
         ) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, %{"items" => body}}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, map} when is_map(map) -> {:ok, map}
          {:ok, list} when is_list(list) -> {:ok, %{"items" => list}}
          {:ok, other} -> {:ok, %{"data" => other}}
          err -> err
        end

      {:ok, %{status: status, body: body}} ->
        {:error, {:http, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
