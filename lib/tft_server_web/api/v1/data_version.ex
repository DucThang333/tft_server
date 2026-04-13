defmodule TftServerWeb.Api.V1.DataVersion do
  @moduledoc "Đọc `versionId` / `version_id` (query) hoặc header `x-data-version`; mặc định `default`."

  import Plug.Conn

  @spec id(Plug.Conn.t()) :: String.t()
  def id(conn) do
    q = conn.query_params["versionId"] || conn.query_params["version_id"]
    h = conn |> get_req_header("x-data-version") |> List.first()
    normalize(q || h || "default")
  end

  defp normalize(nil), do: "default"
  defp normalize(""), do: "default"

  defp normalize(v) do
    case v |> to_string() |> String.trim() do
      "" -> "default"
      id -> id
    end
  end
end
