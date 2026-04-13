defmodule TftServerWeb.Api.V1.Admin.RoleTypeController do
  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs = extract_payload(params)

    case Champions.create_role_type(attrs) do
      {:ok, row} ->
        conn
        |> put_status(:created)
        |> json(%{"roleType" => Json.game_role_type(row)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = extract_payload(params)

    case Champions.get_role_type(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy vai trò"]}})

      row ->
        case Champions.update_role_type(row, attrs) do
          {:ok, updated} ->
            json(conn, %{"roleType" => Json.game_role_type(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Champions.get_role_type(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy vai trò"]}})

      row ->
        case Champions.delete_role_type(row) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, :in_use} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              "errors" => %{
                "base" => ["đang được dùng bởi tướng — đổi vai trò tướng trước"]
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
      %{"roleType" => body} when is_map(body) -> body
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
