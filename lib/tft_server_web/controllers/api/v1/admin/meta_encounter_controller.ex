defmodule TftServerWeb.Api.V1.Admin.MetaEncounterController do
  use TftServerWeb, :controller

  alias TftServer.Meta
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs =
      params
      |> extract_payload()
      |> merge_version_from_params(params)

    case Meta.create_game_encounter(attrs) do
      {:ok, row} ->
        conn
        |> put_status(:created)
        |> json(%{"encounter" => Json.game_encounter(row)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = extract_payload(params)

    case Meta.get_game_encounter(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy kỳ ngộ"]}})

      row ->
        case Meta.update_game_encounter(row, attrs) do
          {:ok, updated} ->
            json(conn, %{"encounter" => Json.game_encounter(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  defp extract_payload(params) when is_map(params) do
    case params do
      %{"encounter" => body} when is_map(body) -> body
      other -> other
    end
  end

  defp merge_version_from_params(body, params)
       when is_map(body) and is_map(params) do
    if Map.has_key?(body, "versionId") or Map.has_key?(body, "version_id") do
      body
    else
      cond do
        Map.has_key?(params, "versionId") -> Map.put(body, "versionId", params["versionId"])
        Map.has_key?(params, "version_id") -> Map.put(body, "version_id", params["version_id"])
        true -> body
      end
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
