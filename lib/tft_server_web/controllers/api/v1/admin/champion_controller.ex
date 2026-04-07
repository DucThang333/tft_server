defmodule TftServerWeb.Api.V1.Admin.ChampionController do
  @moduledoc """
  API admin: tạo / cập nhật tướng kèm `augmentState` (trạng thái lõi) và `encounters` (kỳ ngộ).
  """

  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.Json

  def create(conn, params) do
    attrs = params |> extract_champion_payload() |> normalize_attrs()

    case Champions.create_champion(attrs) do
      {:ok, champion} ->
        conn
        |> put_status(:created)
        |> json(%{"champion" => Json.champion(champion)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => format_errors(cs)})

      {:error, other} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors" => %{"base" => [inspect(other)]}})
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs =
      params
      |> extract_champion_payload()
      |> update_attrs_from_body()

    case Champions.get_champion(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"id" => ["không tìm thấy tướng"]}})

      champion ->
        case Champions.update_champion(champion, attrs) do
          {:ok, updated} ->
            json(conn, %{"champion" => Json.champion(updated)})

          {:error, %Ecto.Changeset{} = cs} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => format_errors(cs)})

          {:error, other} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{"errors" => %{"base" => [inspect(other)]}})
        end
    end
  end

  defp extract_champion_payload(params) when is_map(params) do
    case params do
      %{"champion" => body} when is_map(body) -> body
      other -> other
    end
  end

  defp normalize_attrs(body) when is_map(body) do
    %{
      "id" => body["id"],
      "name" => body["name"],
      "cost" => body["cost"],
      "role_type" => body["roleType"] || body["role_type"],
      "skill_name" => body["skillName"] || body["skill_name"],
      "skill_description_template" =>
        body["skillDescriptionTemplate"] || body["skill_description_template"],
      "traits" => body["traits"] || [],
      "starStats" => body["starStats"] || body["star_stats"] || [],
      "skillParams" => body["skillParams"] || body["skill_params"] || [],
      "image_url" => body["imageUrl"] || body["image_url"],
      "version_id" => body["versionId"] || body["version_id"] || "default",
      "augment_state" => normalize_augment_state(body["augmentState"] || body["augment_state"]),
      "encounters" => normalize_encounters_list(body["encounters"])
    }
  end

  defp normalize_augment_state(nil), do: %{"linked" => [], "notes" => nil}

  defp normalize_augment_state(st) when is_map(st) do
    linked = Map.get(st, "linked") || Map.get(st, :linked) || []
    linked = if is_list(linked), do: linked, else: []
    notes = Map.get(st, "notes", Map.get(st, :notes))
    %{"linked" => linked, "notes" => notes}
  end

  defp normalize_augment_state(_), do: %{"linked" => [], "notes" => nil}

  defp normalize_encounters_list(nil), do: []

  defp normalize_encounters_list(list) when is_list(list), do: list

  defp normalize_encounters_list(_), do: []

  defp update_attrs_from_body(body) when is_map(body) do
    %{}
    |> put_if_key(body, "name", "name")
    |> put_if_key(body, "cost", "cost")
    |> put_if_role_type(body)
    |> put_if_skill_name(body)
    |> put_if_skill_template(body)
    |> put_if_key(body, "traits", "traits")
    |> put_if_star_stats(body)
    |> put_if_skill_params(body)
    |> put_if_image_url(body)
    |> put_if_version_id(body)
    |> put_if_augment_state(body)
    |> put_if_encounters(body)
  end

  defp put_if_role_type(acc, body) do
    cond do
      Map.has_key?(body, "roleType") -> Map.put(acc, "role_type", body["roleType"])
      Map.has_key?(body, "role_type") -> Map.put(acc, "role_type", body["role_type"])
      true -> acc
    end
  end

  defp put_if_skill_name(acc, body) do
    cond do
      Map.has_key?(body, "skillName") -> Map.put(acc, "skill_name", body["skillName"])
      Map.has_key?(body, "skill_name") -> Map.put(acc, "skill_name", body["skill_name"])
      true -> acc
    end
  end

  defp put_if_skill_template(acc, body) do
    cond do
      Map.has_key?(body, "skillDescriptionTemplate") ->
        Map.put(acc, "skill_description_template", body["skillDescriptionTemplate"])

      Map.has_key?(body, "skill_description_template") ->
        Map.put(acc, "skill_description_template", body["skill_description_template"])

      true ->
        acc
    end
  end

  defp put_if_star_stats(acc, body) do
    cond do
      Map.has_key?(body, "starStats") -> Map.put(acc, "starStats", body["starStats"])
      Map.has_key?(body, "star_stats") -> Map.put(acc, "star_stats", body["star_stats"])
      true -> acc
    end
  end

  defp put_if_skill_params(acc, body) do
    cond do
      Map.has_key?(body, "skillParams") -> Map.put(acc, "skillParams", body["skillParams"])
      Map.has_key?(body, "skill_params") -> Map.put(acc, "skill_params", body["skill_params"])
      true -> acc
    end
  end

  defp put_if_key(acc, body, json_key, attr_key) do
    if Map.has_key?(body, json_key), do: Map.put(acc, attr_key, body[json_key]), else: acc
  end

  defp put_if_image_url(acc, body) do
    cond do
      Map.has_key?(body, "imageUrl") -> Map.put(acc, "image_url", body["imageUrl"])
      Map.has_key?(body, "image_url") -> Map.put(acc, "image_url", body["image_url"])
      true -> acc
    end
  end

  defp put_if_version_id(acc, body) do
    cond do
      Map.has_key?(body, "versionId") -> Map.put(acc, "version_id", body["versionId"])
      Map.has_key?(body, "version_id") -> Map.put(acc, "version_id", body["version_id"])
      true -> acc
    end
  end

  defp put_if_augment_state(acc, body) do
    cond do
      Map.has_key?(body, "augmentState") ->
        Map.put(acc, "augment_state", normalize_augment_state(body["augmentState"]))

      Map.has_key?(body, "augment_state") ->
        Map.put(acc, "augment_state", normalize_augment_state(body["augment_state"]))

      true ->
        acc
    end
  end

  defp put_if_encounters(acc, body) do
    if Map.has_key?(body, "encounters") do
      Map.put(acc, "encounters", normalize_encounters_list(body["encounters"]))
    else
      acc
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
