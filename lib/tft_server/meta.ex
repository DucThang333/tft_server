defmodule TftServer.Meta do
  @moduledoc false

  import Ecto.Query

  alias TftServer.DescriptionParams
  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, GameAugment, GameEncounter, MetaOverview, Version}
  alias TftServer.Repo

  def list_compositions do
    traits_ordered = from(tt in CompositionTrait, order_by: [desc: tt.inserted_at, asc: tt.name])
    champions_ordered =
      from(cc in CompositionChampion, order_by: [asc: cc.sort_order, desc: cc.inserted_at])

    from(c in Composition,
      order_by: [desc: c.inserted_at, asc: c.id],
      preload: [traits: ^traits_ordered, champions: ^champions_ordered]
    )
    |> Repo.all()
  end

  def get_overview do
    Repo.get_by(MetaOverview, id: "default")
  end

  def list_versions do
    from(v in Version, order_by: [desc: v.is_active, desc: v.inserted_at, asc: v.id])
    |> Repo.all()
  end

  def list_game_augments(version_id \\ "default") do
    vid = normalize_version_id(version_id)
    from(a in GameAugment,
      where: a.version_id == ^vid,
      order_by: [desc: a.inserted_at, asc: a.id]
    )
    |> Repo.all()
  end

  def get_game_augment(id) when is_binary(id), do: Repo.get(GameAugment, id)

  def create_game_augment(attrs) when is_map(attrs) do
    attrs = normalize_augment_write(attrs)
    %GameAugment{} |> GameAugment.changeset(attrs) |> Repo.insert()
  end

  def update_game_augment(%GameAugment{} = row, attrs) when is_map(attrs) do
    attrs = normalize_augment_patch(attrs)
    row |> GameAugment.changeset(attrs) |> Repo.update()
  end

  def list_game_encounters(version_id \\ "default") do
    vid = normalize_version_id(version_id)
    from(e in GameEncounter,
      where: e.version_id == ^vid,
      order_by: [desc: e.inserted_at, asc: e.id]
    )
    |> Repo.all()
  end

  def get_game_encounter(id) when is_binary(id), do: Repo.get(GameEncounter, id)

  def create_game_encounter(attrs) when is_map(attrs) do
    attrs = normalize_encounter_write(attrs)
    %GameEncounter{} |> GameEncounter.changeset(attrs) |> Repo.insert()
  end

  def update_game_encounter(%GameEncounter{} = row, attrs) when is_map(attrs) do
    attrs = normalize_encounter_patch(attrs)
    row |> GameEncounter.changeset(attrs) |> Repo.update()
  end

  defp normalize_augment_write(a) do
    a = DescriptionParams.stringify_keys_map(a)

    %{
      "id" => a["id"] |> to_string() |> String.trim() |> String.downcase(),
      "name" => a["name"] |> to_string() |> String.trim(),
      "tier" => normalize_augment_tier(a["tier"]),
      "description" => to_string(a["description"] || ""),
      "image_url" => to_string(a["image_url"] || a["imageUrl"] || ""),
      "version_id" => normalize_version_id(a["version_id"] || a["versionId"]),
      "description_params" =>
        DescriptionParams.normalize_list(a["description_params"] || a["descriptionParams"] || [])
    }
  end

  defp normalize_augment_patch(a) do
    a = DescriptionParams.stringify_keys_map(a)

    %{}
    |> put_if_present(a, "name", fn v -> v |> to_string() |> String.trim() end)
    |> put_if_present(a, "tier", &normalize_augment_tier/1)
    |> put_if_present(a, "description", &to_string/1)
    |> put_if_present(a, "image_url", &to_string/1)
    |> put_if_present(a, "imageUrl", &to_string/1, "image_url")
    |> put_if_present(a, "version_id", &normalize_version_id/1)
    |> put_if_present(a, "versionId", &normalize_version_id/1, "version_id")
    |> put_description_params_if_present(a)
  end

  defp normalize_encounter_write(a) do
    a = DescriptionParams.stringify_keys_map(a)

    %{
      "id" => a["id"] |> to_string() |> String.trim() |> String.downcase(),
      "name" => a["name"] |> to_string() |> String.trim(),
      "description" => to_string(a["description"] || ""),
      "image_url" => to_string(a["image_url"] || a["imageUrl"] || ""),
      "version_id" => normalize_version_id(a["version_id"] || a["versionId"]),
      "description_params" =>
        DescriptionParams.normalize_list(a["description_params"] || a["descriptionParams"] || [])
    }
  end

  defp normalize_encounter_patch(a) do
    a = DescriptionParams.stringify_keys_map(a)

    %{}
    |> put_if_present(a, "name", fn v -> v |> to_string() |> String.trim() end)
    |> put_if_present(a, "description", &to_string/1)
    |> put_if_present(a, "image_url", &to_string/1)
    |> put_if_present(a, "imageUrl", &to_string/1, "image_url")
    |> put_if_present(a, "version_id", &normalize_version_id/1)
    |> put_if_present(a, "versionId", &normalize_version_id/1, "version_id")
    |> put_description_params_if_present(a)
  end

  defp normalize_augment_tier(v) do
    case v |> to_string() |> String.trim() |> String.downcase() do
      "gold" -> "gold"
      "prismatic" -> "prismatic"
      _ -> "silver"
    end
  end

  defp normalize_version_id(nil), do: "default"
  defp normalize_version_id(""), do: "default"

  defp normalize_version_id(v) do
    case v |> to_string() |> String.trim() do
      "" -> "default"
      id -> id
    end
  end

  defp put_if_present(acc, map, from_key, fun), do: put_if_present(acc, map, from_key, fun, from_key)

  defp put_if_present(acc, map, from_key, fun, to_key) do
    if Map.has_key?(map, from_key) do
      Map.put(acc, to_key, fun.(map[from_key]))
    else
      acc
    end
  end

  defp put_description_params_if_present(acc, a) do
    if Map.has_key?(a, "description_params") or Map.has_key?(a, "descriptionParams") do
      raw = a["description_params"] || a["descriptionParams"] || []
      Map.put(acc, "description_params", DescriptionParams.normalize_list(raw))
    else
      acc
    end
  end
end
