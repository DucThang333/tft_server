defmodule TftServer.Champions do
  @moduledoc """
  Context tướng: tộc hệ M:N (`traits` + `champion_traits`), chỉ số theo sao, tham số kỹ năng.
  Mô tả kỹ năng dùng `skill_description_template` với placeholder `{{param_key}}` khớp `champion_skill_params.param_key`.
  """

  import Ecto.Query

  alias TftServer.Champions.{
    Champion,
    ChampionSkillParam,
    ChampionStarStat,
    ChampionTrait,
    Trait
  }

  alias Ecto.Multi
  alias TftServer.Repo

  def list_champions do
    Champion
    |> order_by([c], asc: c.id)
    |> preload(^champion_preloads())
    |> Repo.all()
  end

  @doc """
  Tất cả định nghĩa tộc/hệ (bách khoa / meta traits), sắp xếp theo tên.
  """
  def list_trait_defs do
    Trait
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def get_trait_def(id) when is_binary(id), do: Repo.get(Trait, id)

  def create_trait_def(attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    name = attrs["name"] |> to_string() |> String.trim()

    trait_attrs = %{
      "id" => normalize_trait_id(attrs["id"], name),
      "name" => name,
      "kind" => normalize_trait_kind(attrs["kind"]),
      "description" => attrs["description"] || "",
      "icon_url" => attrs["icon_url"] || attrs["iconUrl"] || "",
      "version_id" => normalize_version_id(attrs["version_id"] || attrs["versionId"])
    }

    %Trait{}
    |> Trait.changeset(trait_attrs)
    |> Repo.insert()
  end

  def update_trait_def(%Trait{} = trait, attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)

    update_attrs =
      %{}
      |> put_if_present(attrs, "name", fn v -> String.trim(to_string(v)) end)
      |> put_if_present(attrs, "kind", &normalize_trait_kind/1)
      |> put_if_present(attrs, "description", &to_string/1)
      |> put_if_present(attrs, "icon_url", &to_string/1)
      |> put_if_present(attrs, "iconUrl", &to_string/1, "icon_url")
      |> put_if_present(attrs, "version_id", &normalize_version_id/1)
      |> put_if_present(attrs, "versionId", &normalize_version_id/1, "version_id")

    trait
    |> Trait.changeset(update_attrs)
    |> Repo.update()
  end

  def delete_trait_def(%Trait{} = trait), do: Repo.delete(trait)

  def get_champion(id) when is_binary(id) do
    Champion
    |> where([c], c.id == ^id)
    |> preload(^champion_preloads())
    |> Repo.one()
  end

  defp champion_preloads do
    [
      champion_traits:
        from(ct in ChampionTrait,
          order_by: [asc: ct.sort_order, asc: ct.trait_id],
          preload: [:trait]
        ),
      star_stats: from(s in ChampionStarStat, order_by: [asc: s.stars]),
      skill_params: from(p in ChampionSkillParam, order_by: [asc: p.sort_order, asc: p.param_key])
    ]
  end

  @doc """
  Tạo tướng kèm tộc hệ (M:N), chỉ số theo sao, tham số kỹ năng.
  `attrs` dùng string keys: traits, starStats, skillParams (hoặc snake_case).
  """
  def create_champion(attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    trait_names = extract_trait_names(attrs)
    star_stats = extract_star_stats(attrs)
    skill_params = extract_skill_params(attrs)
    base = Map.drop(attrs, ["traits", "star_stats", "starStats", "skill_params", "skillParams"])

    cond do
      trait_names == [] ->
        {:error, invalid_traits_changeset()}

      star_stats == [] ->
        {:error, invalid_star_stats_changeset()}

      true ->
        base =
          base
          |> Map.put_new("content_version", 1)
          |> Map.put_new("version_id", "default")

        Multi.new()
        |> Multi.insert(:champion, Champion.create_changeset(%Champion{}, base))
        |> Multi.run(:traits, fn repo, %{champion: c} ->
          insert_champion_traits(repo, c.id, trait_names)
        end)
        |> Multi.run(:star_stats, fn repo, %{champion: c} ->
          insert_star_stats(repo, c.id, star_stats)
        end)
        |> Multi.run(:skill_params, fn repo, %{champion: c} ->
          insert_skill_params(repo, c.id, skill_params)
        end)
        |> Repo.transaction()
        |> normalize_multi_result(:champion)
    end
  end

  def update_champion(%Champion{} = champion, attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    trait_names = extract_trait_names_optional(attrs)
    star_stats = extract_star_stats_optional(attrs)
    skill_params = extract_skill_params_optional(attrs)

    base =
      attrs
      |> Map.drop(["traits", "star_stats", "starStats", "skill_params", "skillParams"])
      |> Map.put("content_version", (champion.content_version || 1) + 1)

    Multi.new()
    |> Multi.update(:champion, Champion.update_changeset(champion, base))
    |> Multi.run(:traits, fn repo, %{champion: c} ->
      if trait_names == :absent do
        {:ok, :skipped}
      else
        replace_champion_traits(repo, c.id, trait_names)
      end
    end)
    |> Multi.run(:star_stats, fn repo, %{champion: c} ->
      if star_stats == :absent do
        {:ok, :skipped}
      else
        replace_star_stats(repo, c.id, star_stats)
      end
    end)
    |> Multi.run(:skill_params, fn repo, %{champion: c} ->
      if skill_params == :absent do
        {:ok, :skipped}
      else
        replace_skill_params(repo, c.id, skill_params)
      end
    end)
    |> Repo.transaction()
    |> normalize_multi_result(:champion)
  end

  defp normalize_multi_result(result, champion_key) do
    case result do
      {:ok, %{^champion_key => champion}} ->
        {:ok, get_champion(champion.id)}

      {:error, :champion, cs, _} ->
        {:error, cs}

      {:error, _step, %Ecto.Changeset{} = cs, _} ->
        {:error, cs}

      {:error, _step, other, _} ->
        {:error, other}
    end
  end

  defp invalid_traits_changeset do
    %Champion{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:traits, "cần ít nhất một tộc hệ")
  end

  defp invalid_star_stats_changeset do
    %Champion{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:star_stats, "cần ít nhất một dòng chỉ số theo sao")
  end

  defp insert_champion_traits(repo, champion_id, trait_names) do
    Enum.with_index(trait_names, 0)
    |> Enum.reduce_while({:ok, :ok}, fn {name, idx}, {:ok, _} ->
      with {:ok, trait} <- find_trait(repo, name),
           {:ok, _} <-
             %ChampionTrait{}
             |> ChampionTrait.changeset(%{
               champion_id: champion_id,
               trait_id: trait.id,
               sort_order: idx
             })
             |> repo.insert() do
        {:cont, {:ok, :ok}}
      else
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp replace_champion_traits(repo, champion_id, trait_names) do
    repo.delete_all(from(ct in ChampionTrait, where: ct.champion_id == ^champion_id))

    if trait_names == [] do
      {:error, invalid_traits_changeset()}
    else
      insert_champion_traits(repo, champion_id, trait_names)
    end
  end

  defp find_trait(repo, name) when is_binary(name) do
    id = trait_id_from_name(name)

    case repo.get(Trait, id) do
      %Trait{} = t ->
        {:ok, t}

      nil ->
        case repo.one(from(t in Trait, where: t.name == ^name, limit: 1)) do
          %Trait{} = t -> {:ok, t}
          nil -> {:error, invalid_missing_trait_changeset(name)}
        end
    end
  end

  defp invalid_missing_trait_changeset(name) do
    %Champion{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:traits, "tộc hệ chưa tồn tại: #{name}")
  end

  defp trait_id_from_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp insert_star_stats(repo, champion_id, rows) do
    Enum.reduce_while(rows, {:ok, :ok}, fn row, {:ok, _} ->
      row = Map.put(row, :champion_id, champion_id)

      case %ChampionStarStat{}
           |> ChampionStarStat.changeset(row)
           |> repo.insert() do
        {:ok, _} -> {:cont, {:ok, :ok}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp replace_star_stats(repo, champion_id, rows) do
    repo.delete_all(from(s in ChampionStarStat, where: s.champion_id == ^champion_id))

    if rows == [] do
      {:error, invalid_star_stats_changeset()}
    else
      insert_star_stats(repo, champion_id, rows)
    end
  end

  defp insert_skill_params(repo, champion_id, rows) do
    Enum.reduce_while(rows, {:ok, :ok}, fn row, {:ok, _} ->
      row = Map.put(row, :champion_id, champion_id)

      case %ChampionSkillParam{}
           |> ChampionSkillParam.changeset(row)
           |> repo.insert() do
        {:ok, _} -> {:cont, {:ok, :ok}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp replace_skill_params(repo, champion_id, rows) do
    repo.delete_all(from(p in ChampionSkillParam, where: p.champion_id == ^champion_id))
    insert_skill_params(repo, champion_id, rows)
  end

  defp extract_trait_names(attrs) do
    (Map.get(attrs, "traits") || [])
    |> List.wrap()
    |> Enum.map(&normalize_trait_entry/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_trait_names_optional(attrs) do
    if Map.has_key?(attrs, "traits") do
      extract_trait_names(attrs)
    else
      :absent
    end
  end

  defp normalize_trait_entry(%{"name" => name}) when is_binary(name), do: String.trim(name)
  defp normalize_trait_entry(name) when is_binary(name), do: String.trim(name)
  defp normalize_trait_entry(_), do: ""

  defp extract_star_stats(attrs) do
    raw =
      case Map.get(attrs, "starStats") do
        nil -> Map.get(attrs, "star_stats") || []
        v -> v
      end

    raw |> List.wrap() |> Enum.map(&normalize_star_stat_row/1) |> Enum.reject(&(&1 == nil))
  end

  defp extract_star_stats_optional(attrs) do
    cond do
      Map.has_key?(attrs, "starStats") -> extract_star_stats(attrs)
      Map.has_key?(attrs, "star_stats") -> extract_star_stats(attrs)
      true -> :absent
    end
  end

  defp normalize_star_stat_row(row) when is_map(row) do
    stars = pick_int(row, ["stars", "star"])
    if is_nil(stars), do: nil, else: %{
      stars: stars,
      hp: pick_int(row, ["hp"]),
      mana_initial: pick_int(row, ["manaInitial", "mana_initial"]),
      mana_max: pick_int(row, ["manaMax", "mana_max"]),
      attack_damage: pick_int(row, ["attackDamage", "attack_damage"]),
      ability_power: pick_int(row, ["abilityPower", "ability_power"]),
      armor: pick_int(row, ["armor"]),
      magic_resist: pick_int(row, ["magicResist", "magic_resist"]),
      attack_speed: pick_float(row, ["attackSpeed", "attack_speed"]),
      crit_chance: pick_float(row, ["critChance", "crit_chance"]),
      crit_damage: pick_float(row, ["critDamage", "crit_damage"]),
      attack_range: pick_int(row, ["attackRange", "attack_range"])
    }
  end

  defp normalize_star_stat_row(_), do: nil

  defp pick_int(row, keys) do
    Enum.find_value(keys, fn k ->
      case Map.get(row, k) do
        nil -> nil
        v when is_integer(v) -> v
        v when is_float(v) -> trunc(v)
        v when is_binary(v) -> parse_int_string(v)
      end
    end)
  end

  defp parse_int_string(v) do
    case Integer.parse(String.trim(v)) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp pick_float(row, keys) do
    Enum.find_value(keys, fn k ->
      case Map.get(row, k) do
        nil -> nil
        v when is_float(v) -> v
        v when is_integer(v) -> v * 1.0
        v when is_binary(v) -> parse_float_string(v)
      end
    end)
  end

  defp parse_float_string(v) do
    s = String.trim(v)

    case Float.parse(s) do
      {f, _} ->
        f

      :error ->
        case parse_int_string(s) do
          nil -> nil
          i -> i * 1.0
        end
    end
  end

  defp extract_skill_params(attrs) do
    raw =
      case Map.get(attrs, "skillParams") do
        nil -> Map.get(attrs, "skill_params") || []
        v -> v
      end

    raw
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.map(fn {el, i} -> normalize_skill_param_row(el, i) end)
  end

  defp extract_skill_params_optional(attrs) do
    cond do
      Map.has_key?(attrs, "skillParams") -> extract_skill_params(attrs)
      Map.has_key?(attrs, "skill_params") -> extract_skill_params(attrs)
      true -> :absent
    end
  end

  defp normalize_skill_param_row(row, default_order) when is_map(row) do
    key = Map.get(row, "paramKey") || Map.get(row, "param_key")
    label = Map.get(row, "displayLabel") || Map.get(row, "display_label")
    vals = Map.get(row, "starValues") || Map.get(row, "star_values") || []
    vals = vals |> List.wrap() |> Enum.map(&to_float_val/1)
    scales = Map.get(row, "scalesWith") || Map.get(row, "scales_with")
    order = Map.get(row, "sortOrder") || Map.get(row, "sort_order") || default_order

    %{
      param_key: key,
      display_label: label,
      star_values: vals,
      scales_with: blank_to_nil(scales),
      sort_order: order
    }
  end

  defp normalize_skill_param_row(_, default_order) do
    %{
      param_key: nil,
      display_label: nil,
      star_values: [],
      scales_with: nil,
      sort_order: default_order
    }
  end

  defp to_float_val(v) when is_float(v), do: v
  defp to_float_val(v) when is_integer(v), do: v * 1.0

  defp to_float_val(v) when is_binary(v) do
    case parse_float_string(v) do
      nil -> 0.0
      f -> f
    end
  end

  defp blank_to_nil(v) when v in [nil, ""], do: nil
  defp blank_to_nil(v), do: v

  defp put_if_present(acc, map, from_key, transform),
    do: put_if_present(acc, map, from_key, transform, from_key)

  defp put_if_present(acc, map, from_key, transform, to_key) do
    if Map.has_key?(map, from_key) do
      Map.put(acc, to_key, transform.(map[from_key]))
    else
      acc
    end
  end

  defp normalize_trait_id(nil, name), do: trait_id_from_name(name)
  defp normalize_trait_id("", name), do: trait_id_from_name(name)
  defp normalize_trait_id(id, _name), do: id |> to_string() |> String.trim()

  defp normalize_trait_kind(kind) when kind in ["class", :class], do: "class"
  defp normalize_trait_kind(_), do: "origin"

  defp normalize_version_id(nil), do: "default"
  defp normalize_version_id(""), do: "default"
  defp normalize_version_id(v) do
    case v |> to_string() |> String.trim() do
      "" -> "default"
      id -> id
    end
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} when is_binary(k) -> {k, v}
    end)
  end
end
