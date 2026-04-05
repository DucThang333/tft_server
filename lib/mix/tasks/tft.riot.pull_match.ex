defmodule Mix.Tasks.Tft.Riot.PullMatch do
  @moduledoc """
  HTTPS GET Riot `tft/match/v1/matches/{matchId}` and insert a row into `riot_snapshots`.

  ## Examples

      RIOT_API_KEY=rgapi-... mix tft.riot.pull_match --region americas --id NA1_1234567890

  Use the regional route (e.g. americas, europe, asia), not the platform shard.

  API reference: https://developer.riotgames.com/apis#tft-match-v1
  """
  use Mix.Task

  @shortdoc "Pull one TFT match JSON from Riot into the database"

  @impl Mix.Task
  def run(argv) do
    _ = Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [region: :string, id: :string],
        aliases: [r: :region, i: :id]
      )

    api_key = System.get_env("RIOT_API_KEY")

    if api_key == nil or api_key == "" do
      Mix.shell().error("Set RIOT_API_KEY (Riot developer portal).")
      exit({:shutdown, 1})
    end

    region =
      opts[:region] || Application.get_env(:tft_server, :riot, [])[:region] || "americas"
    match_id = opts[:id]

    if match_id == nil or match_id == "" do
      Mix.shell().error("Pass --id MATCH_ID (e.g. NA1_...).")
      exit({:shutdown, 1})
    end

    snapshot = TftServer.Riot.ingest_tft_match!(api_key, region, match_id)

    Mix.shell().info(
      "Stored tft/match/v1/matches/#{match_id} snapshot id=#{snapshot.id} at #{snapshot.inserted_at}"
    )
  end
end
