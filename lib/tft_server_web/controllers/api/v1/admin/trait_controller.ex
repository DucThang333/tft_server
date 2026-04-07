defmodule TftServerWeb.Api.V1.Admin.TraitController do
  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs = extract_trait_payload(params)

    case Champions.create_trait_def(attrs) do
      {:ok, trait} ->
        conn
        |> put_status(:created)
        |> json(%{"trait" => Json.game_trait_def(trait)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = extract_trait_payload(params)

    case Champions.get_trait_def(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy trait"]}})

      trait ->
        case Champions.update_trait_def(trait, attrs) do
          {:ok, updated} ->
            json(conn, %{"trait" => Json.game_trait_def(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Champions.get_trait_def(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy trait"]}})

      trait ->
        case Champions.delete_trait_def(trait) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})
        end
    end
  end

  defp extract_trait_payload(params) when is_map(params) do
    case params do
      %{"trait" => body} when is_map(body) -> body
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
