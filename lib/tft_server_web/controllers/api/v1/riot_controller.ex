defmodule TftServerWeb.Api.V1.RiotController do
  use TftServerWeb, :controller

  alias TftServer.Riot

  @doc """
  Returns the latest stored `tft/status/v1/platform-data` snapshot for a platform shard.
  Ingest with: `mix tft.riot.pull_status --platform na1`
  """
  def platform_status(conn, params) do
    platform =
      params["platform"] ||
        Application.get_env(:tft_server, :riot, [])[:platform] ||
        "na1"

    case Riot.latest_snapshot(Riot.tft_status_endpoint(), platform) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          "error" => "no_snapshot",
          "hint" => "Run: RIOT_API_KEY=... mix tft.riot.pull_status --platform #{platform}"
        })

      snap ->
        json(conn, %{
          "platform" => platform,
          "insertedAt" => NaiveDateTime.to_iso8601(snap.inserted_at),
          "payload" => snap.payload
        })
    end
  end
end
