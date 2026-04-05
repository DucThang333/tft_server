defmodule Mix.Tasks.Tft.Riot.PullMatchIds do
  @moduledoc """
  HTTPS GET `tft/match/v1/matches/by-puuid/{puuid}/ids` and store the ID list in `riot_snapshots`.

  ## Examples

      RIOT_API_KEY=rgapi-... mix tft.riot.pull_match_ids --region americas --puuid <PUUID>

  Optional: `--start 0` `--count 20`

  API reference: https://developer.riotgames.com/apis#tft-match-v1
  """
  use Mix.Task

  @shortdoc "Pull TFT match ID list for a PUUID into the database"

  @endpoint "tft_match_v1_ids_by_puuid"

  @impl Mix.Task
  def run(argv) do
    _ = Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [region: :string, puuid: :string, start: :integer, count: :integer],
        aliases: [r: :region, p: :puuid]
      )

    api_key = System.get_env("RIOT_API_KEY")

    if api_key == nil or api_key == "" do
      Mix.shell().error("Set RIOT_API_KEY (Riot developer portal).")
      exit({:shutdown, 1})
    end

    region =
      opts[:region] || Application.get_env(:tft_server, :riot, [])[:region] || "americas"

    puuid = opts[:puuid]

    if puuid == nil or puuid == "" do
      Mix.shell().error("Pass --puuid <PUUID> (from Account-V1 or summoner flow).")
      exit({:shutdown, 1})
    end

    kw =
      []
      |> maybe_put(:start, opts[:start])
      |> maybe_put(:count, opts[:count])

    case TftServer.Riot.Client.tft_match_ids_by_puuid(api_key, region, puuid, kw) do
      {:ok, body} when is_map(body) ->
        snap = TftServer.Riot.insert_snapshot!(@endpoint, region, puuid, body)
        ids = Map.get(body, "items") || Map.get(body, "data") || body
        Mix.shell().info("Stored #{@endpoint} snapshot id=#{snap.id} ids=#{inspect(ids)}")

      {:error, reason} ->
        Mix.shell().error("Riot API error: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp maybe_put(kw, _k, nil), do: kw
  defp maybe_put(kw, k, v), do: Keyword.put(kw, k, v)
end
