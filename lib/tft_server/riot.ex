defmodule TftServer.Riot do
  @moduledoc """
  Persists raw JSON snapshots from Riot TFT HTTP APIs for auditing and downstream ETL.
  """

  import Ecto.Query

  alias TftServer.Repo
  alias TftServer.Riot.RiotSnapshot

  @tft_status_endpoint "tft_status_v1_platform_data"
  @tft_match_endpoint "tft_match_v1_match"

  def tft_status_endpoint, do: @tft_status_endpoint
  def tft_match_endpoint, do: @tft_match_endpoint

  def insert_snapshot!(endpoint, routing_value, resource_key, payload)
      when is_map(payload) do
    %RiotSnapshot{}
    |> RiotSnapshot.changeset(%{
      endpoint: endpoint,
      routing_value: routing_value,
      resource_key: resource_key,
      payload: payload
    })
    |> Repo.insert!()
  end

  def latest_snapshot(endpoint, routing_value) do
    from(s in RiotSnapshot,
      where: s.endpoint == ^endpoint and s.routing_value == ^routing_value,
      order_by: [desc: s.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Fetch TFT platform status via HTTPS and store a row in `riot_snapshots`.
  """
  def ingest_tft_platform_data!(api_key, platform) do
    case TftServer.Riot.Client.tft_platform_data(api_key, platform) do
      {:ok, body} ->
        insert_snapshot!(@tft_status_endpoint, platform, nil, body)

      {:error, reason} ->
        raise "Riot API error: #{inspect(reason)}"
    end
  end

  @doc """
  Fetch a TFT match by ID (regional host) and store a snapshot.
  """
  def ingest_tft_match!(api_key, region, match_id) do
    case TftServer.Riot.Client.tft_match(api_key, region, match_id) do
      {:ok, body} ->
        insert_snapshot!(@tft_match_endpoint, region, match_id, body)

      {:error, reason} ->
        raise "Riot API error: #{inspect(reason)}"
    end
  end
end
