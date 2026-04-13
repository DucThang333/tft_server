defmodule TftServerWeb.Api.V1.Admin.VersionMigrateController do
  use TftServerWeb, :controller

  alias TftServer.Versioning

  def create(conn, params) do
    from_v = params["fromVersionId"] || params["from_version_id"]
    to_v = params["toVersionId"] || params["to_version_id"]
    entities = parse_entities(params["entities"])

    case Versioning.migrate_data(from_v, to_v, entities) do
      {:ok, migrated} ->
        json(conn, %{"ok" => true, "migrated" => migrated})

      {:error, :same_version} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => "same_version", "message" => "Nguồn và đích phải khác nhau."})

      {:error, :no_entities} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          "error" => "no_entities",
          "message" => "Chọn ít nhất một nhóm dữ liệu (tướng, tộc/hệ, trang bị, …)."
        })

      {:error, :unknown_target_version} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "unknown_target_version", "message" => "Phiên bản đích không tồn tại."})

      {:error, other} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{"error" => "migrate_failed", "detail" => inspect(other)})
    end
  end

  defp parse_entities(nil), do: []
  defp parse_entities(list) when is_list(list), do: list
  defp parse_entities(_), do: []
end
