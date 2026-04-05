defmodule Mix.Tasks.Tft.Riot.PullStatus do
  @moduledoc """
  HTTPS GET Riot `tft/status/v1/platform-data` and insert a row into `riot_snapshots`.

  ## Examples

      RIOT_API_KEY=rgapi-... mix tft.riot.pull_status
      RIOT_API_KEY=rgapi-... mix tft.riot.pull_status --platform euw1

  API reference: https://developer.riotgames.com/apis#tft-status-v1
  """
  use Mix.Task

  @shortdoc "Pull TFT platform status from Riot into the database"

  @impl Mix.Task
  def run(argv) do
    _ = Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [platform: :string],
        aliases: [p: :platform]
      )

    api_key = System.get_env("RIOT_API_KEY")

    if api_key == nil or api_key == "" do
      Mix.shell().error("Set RIOT_API_KEY (Riot developer portal).")
      exit({:shutdown, 1})
    end

    platform =
      opts[:platform] || Application.get_env(:tft_server, :riot, [])[:platform] || "na1"

    snapshot = TftServer.Riot.ingest_tft_platform_data!(api_key, platform)

    Mix.shell().info(
      "Stored tft/status/v1/platform-data for #{platform} snapshot id=#{snapshot.id} at #{snapshot.inserted_at}"
    )
  end
end
