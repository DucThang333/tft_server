defmodule TftServerWeb.Api.V1.Admin.ScalesWithOptionController do
  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs = extract_payload(params)

    case Champions.create_scales_with_option(attrs) do
      {:ok, row} ->
        conn
        |> put_status(:created)
        |> json(%{"scalesWithOption" => Json.scales_with_option(row)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = extract_payload(params)

    case Champions.get_scales_with_option(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy"]}})

      row ->
        case Champions.update_scales_with_option(row, attrs) do
          {:ok, updated} ->
            json(conn, %{"scalesWithOption" => Json.scales_with_option(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Champions.get_scales_with_option(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy"]}})

      row ->
        case Champions.delete_scales_with_option(row) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, :in_use} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              "errors" => %{
                "base" => ["đang được dùng bởi tham số kỹ năng tướng — gỡ scalesWith trước"]
              }
            })

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  defp extract_payload(params) when is_map(params) do
    case params do
      %{"scalesWithOption" => body} when is_map(body) -> body
      other -> other
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
