defmodule TftServer.Items do
  @moduledoc false

  import Ecto.Query

  alias TftServer.DescriptionParams
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Repo

  def list_base_items(version_id \\ "default") do
    vid = normalize_version_id(version_id)
    from(i in BaseItem,
      where: i.version_id == ^vid,
      order_by: [desc: i.inserted_at, asc: i.id]
    )
    |> Repo.all()
  end

  def list_combined_items(version_id \\ "default") do
    vid = normalize_version_id(version_id)
    from(i in CombinedItem,
      where: i.version_id == ^vid,
      order_by: [desc: i.inserted_at, asc: i.id]
    )
    |> Repo.all()
  end

  def get_combined_item(id) when is_binary(id), do: Repo.get(CombinedItem, id)

  def create_combined_item(attrs) when is_map(attrs) do
    attrs = normalize_combined_write_attrs(attrs)

    %CombinedItem{}
    |> CombinedItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_combined_item(%CombinedItem{} = row, attrs) when is_map(attrs) do
    attrs = normalize_combined_update_attrs(attrs)

    row
    |> CombinedItem.changeset(attrs)
    |> Repo.update()
  end

  defp normalize_combined_write_attrs(attrs) do
    a = DescriptionParams.stringify_keys_map(attrs)

    %{
      "id" => a["id"] |> to_string() |> String.trim(),
      "name" => a["name"] |> to_string() |> String.trim(),
      "description" => to_string(a["description"] || ""),
      "components" => normalize_components(a["components"]),
      "component_names" =>
        to_string(a["component_names"] || a["componentNames"] || "") |> String.trim(),
      "tier" => blank_str_to_nil(a["tier"]),
      "tags" => normalize_string_list(a["tags"]),
      "image_url" => to_string(a["image_url"] || a["imageUrl"] || ""),
      "stats" => normalize_stats_list(a["stats"]),
      "version_id" => normalize_version_id(a["version_id"] || a["versionId"]),
      "description_params" =>
        DescriptionParams.normalize_list(a["description_params"] || a["descriptionParams"] || [])
    }
  end

  defp normalize_combined_update_attrs(attrs) do
    a = DescriptionParams.stringify_keys_map(attrs)

    %{}
    |> put_if_present(a, "name", fn v -> v |> to_string() |> String.trim() end)
    |> put_if_present(a, "description", &to_string/1)
    |> put_if_present_components(a)
    |> put_if_present(a, "component_names", &to_string/1)
    |> put_if_present(a, "componentNames", &to_string/1, "component_names")
    |> put_if_present_tier(a)
    |> put_if_present_tags(a)
    |> put_if_present(a, "image_url", &to_string/1)
    |> put_if_present(a, "imageUrl", &to_string/1, "image_url")
    |> put_if_present_stats(a)
    |> put_if_present(a, "version_id", &normalize_version_id/1)
    |> put_if_present(a, "versionId", &normalize_version_id/1, "version_id")
    |> put_description_params_if_present(a)
  end

  defp put_if_present(acc, map, from_key, fun), do: put_if_present(acc, map, from_key, fun, from_key)

  defp put_if_present(acc, map, from_key, fun, to_key) do
    if Map.has_key?(map, from_key) do
      Map.put(acc, to_key, fun.(map[from_key]))
    else
      acc
    end
  end

  defp put_if_present_components(acc, a) do
    cond do
      Map.has_key?(a, "components") ->
        Map.put(acc, "components", normalize_components(a["components"]))

      true ->
        acc
    end
  end

  defp put_if_present_tier(acc, a) do
    if Map.has_key?(a, "tier") do
      Map.put(acc, "tier", blank_str_to_nil(a["tier"]))
    else
      acc
    end
  end

  defp put_if_present_tags(acc, a) do
    if Map.has_key?(a, "tags") do
      Map.put(acc, "tags", normalize_string_list(a["tags"]))
    else
      acc
    end
  end

  defp put_if_present_stats(acc, a) do
    if Map.has_key?(a, "stats") do
      Map.put(acc, "stats", normalize_stats_list(a["stats"]))
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

  defp normalize_components(nil), do: []

  defp normalize_components(list) when is_list(list) do
    list |> Enum.map(&to_string/1) |> Enum.map(&String.trim/1)
  end

  defp normalize_components(_), do: []

  defp normalize_string_list(nil), do: []

  defp normalize_string_list(list) when is_list(list) do
    Enum.map(list, &to_string/1)
  end

  defp normalize_string_list(_), do: []

  defp normalize_stats_list(nil), do: []

  defp normalize_stats_list(list) when is_list(list) do
    Enum.map(list, fn
      %{"label" => l, "value" => v} ->
        %{"label" => to_string(l), "value" => to_string(v)}

      %{label: l, value: v} ->
        %{"label" => to_string(l), "value" => to_string(v)}

      _ ->
        %{"label" => "", "value" => ""}
    end)
  end

  defp normalize_stats_list(_), do: []

  defp blank_str_to_nil(v) when v in [nil, ""], do: nil

  defp blank_str_to_nil(v) do
    s = to_string(v) |> String.trim()
    if s == "", do: nil, else: s
  end

  defp normalize_version_id(nil), do: "default"
  defp normalize_version_id(""), do: "default"

  defp normalize_version_id(v) do
    case v |> to_string() |> String.trim() do
      "" -> "default"
      id -> id
    end
  end
end
