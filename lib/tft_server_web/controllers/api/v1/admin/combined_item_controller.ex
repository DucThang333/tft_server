defmodule TftServerWeb.Api.V1.Admin.CombinedItemController do
  use TftServerWeb, :controller

  alias TftServer.Items
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs =
      params
      |> extract_item_payload()
      |> merge_version_from_params(params)

    case Items.create_combined_item(attrs) do
      {:ok, row} ->
        conn
        |> put_status(:created)
        |> json(%{"item" => Json.combined_item(row)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = extract_item_payload(params)

    case Items.get_combined_item(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy trang bị ghép"]}})

      row ->
        case Items.update_combined_item(row, attrs) do
          {:ok, updated} ->
            json(conn, %{"item" => Json.combined_item(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  defp extract_item_payload(params) when is_map(params) do
    case params do
      %{"item" => body} when is_map(body) -> body
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
