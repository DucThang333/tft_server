defmodule TftServer.Champions do
  @moduledoc """
  Context tướng: tộc hệ M:N (`traits` + `champion_traits`), chỉ số theo sao, tham số kỹ năng.
  Mô tả kỹ năng dùng `skill_description_template` với placeholder `{{param_key}}` khớp `champion_skill_params.param_key`.
  Mỗi `champion_skill_params.star_values` có thể có **1–4** số (theo bậc sao).
  """

  import Ecto.Query

  alias TftServer.Champions.{
    Champion,
    ChampionSkill,
    ChampionSkillParam,
    ChampionStarStat,
    ChampionTrait,
    RoleType,
    ScalesWithOption,
    Trait
  }

  alias Ecto.Multi
  alias TftServer.DescriptionParams
  alias TftServer.Repo

  def list_champions(version_id \\ "default") do
    vid = normalize_version_id(version_id)

    Champion
    |> where([c], c.version_id == ^vid)
    |> order_by([c], desc: c.inserted_at, asc: c.id)
    |> preload(^champion_preloads())
    |> Repo.all()
  end

  @doc """
  Tất cả định nghĩa tộc/hệ (bách khoa / meta traits), sắp xếp theo `inserted_at` giảm dần.
  """
  def list_trait_defs(version_id \\ "default") do
    vid = normalize_version_id(version_id)

    Trait
    |> where([t], t.version_id == ^vid)
    |> order_by([t], desc: t.inserted_at, asc: t.id)
    |> Repo.all()
  end

  def get_trait_def(id) when is_binary(id), do: Repo.get(Trait, id)

  def create_trait_def(attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)
    name = attrs["name"] |> to_string() |> String.trim()

    trait_attrs = %{
      "id" => normalize_trait_id(attrs["id"], name),
      "name" => name,
      "kind" => normalize_trait_kind(attrs["kind"]),
      "description" => attrs["description"] || "",
      "icon_url" => attrs["icon_url"] || attrs["iconUrl"] || "",
      "version_id" => normalize_version_id(attrs["version_id"] || attrs["versionId"]),
      "description_params" =>
        DescriptionParams.normalize_list(attrs["description_params"] || attrs["descriptionParams"] || [])
    }

    %Trait{}
    |> Trait.changeset(trait_attrs)
    |> Repo.insert()
  end

  def update_trait_def(%Trait{} = trait, attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)

    update_attrs =
      %{}
      |> put_if_present(attrs, "name", fn v -> String.trim(to_string(v)) end)
      |> put_if_present(attrs, "kind", &normalize_trait_kind/1)
      |> put_if_present(attrs, "description", &to_string/1)
      |> put_if_present(attrs, "icon_url", &to_string/1)
      |> put_if_present(attrs, "iconUrl", &to_string/1, "icon_url")
      |> put_if_present(attrs, "version_id", &normalize_version_id/1)
      |> put_if_present(attrs, "versionId", &normalize_version_id/1, "version_id")
      |> put_description_params_if_present(attrs)

    trait
    |> Trait.changeset(update_attrs)
    |> Repo.update()
  end

  def delete_trait_def(%Trait{} = trait), do: Repo.delete(trait)

  @doc """
  Định nghĩa vai trò tướng (`champions.role_type` → id).
  """
  def list_role_types do
    from(r in RoleType, order_by: [desc: r.inserted_at, asc: r.id])
    |> Repo.all()
  end

  def get_role_type(id) when is_binary(id), do: Repo.get(RoleType, id)

  def create_role_type(attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)
    id = attrs["id"] |> to_string() |> String.trim() |> String.downcase()
    name = attrs["name"] |> to_string() |> String.trim()
    color = to_string(attrs["color"] || "#64748b")
    desc = to_string(attrs["description"] || "")

    params =
      DescriptionParams.normalize_list(attrs["description_params"] || attrs["descriptionParams"] || [])

    %RoleType{}
    |> RoleType.changeset(%{
      "id" => id,
      "name" => name,
      "color" => color,
      "description" => desc,
      "description_params" => params
    })
    |> Repo.insert()
  end

  def update_role_type(%RoleType{} = row, attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)

    updates =
      %{}
      |> put_if_present(attrs, "name", fn v -> String.trim(to_string(v)) end)
      |> put_if_present(attrs, "color", &to_string/1)
      |> put_if_present(attrs, "description", &to_string/1)
      |> put_description_params_if_present(attrs)

    row
    |> RoleType.update_changeset(updates)
    |> Repo.update()
  end

  def delete_role_type(%RoleType{} = row) do
    used = Repo.exists?(from c in Champion, where: c.role_type == ^row.id)

    if used do
      {:error, :in_use}
    else
      Repo.delete(row)
    end
  end

  @doc """
  Loại chỉ số kỹ năng (`champion_skill_params.scales_with`) — id, label, icon_url.
  """
  def list_scales_with_options do
    from(s in ScalesWithOption, order_by: [desc: s.inserted_at, asc: s.id])
    |> Repo.all()
  end

  def get_scales_with_option(id) when is_binary(id), do: Repo.get(ScalesWithOption, id)

  def create_scales_with_option(attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)
    id = attrs["id"] |> to_string() |> String.trim() |> String.downcase()
    label = attrs["label"] |> to_string() |> String.trim()
    icon = to_string(attrs["icon_url"] || attrs["iconUrl"] || "")
    text_color = normalize_scales_with_text_color(attrs["text_color"] || attrs["textColor"])

    base = %{
      "id" => id,
      "label" => label,
      "icon_url" => icon,
      "text_color" => text_color
    }

    base =
      case attrs["value_format"] || attrs["valueFormat"] do
        nil -> base
        v -> Map.put(base, "value_format", normalize_scales_with_value_format_string(v))
      end

    %ScalesWithOption{}
    |> ScalesWithOption.changeset(base)
    |> Repo.insert()
  end

  def update_scales_with_option(%ScalesWithOption{} = row, attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)

    updates =
      %{}
      |> put_if_present(attrs, "label", fn v -> String.trim(to_string(v)) end)
      |> put_if_present(attrs, "icon_url", &to_string/1)
      |> put_if_present(attrs, "iconUrl", &to_string/1, "icon_url")
      |> put_if_present(attrs, "text_color", &normalize_scales_with_text_color/1)
      |> put_if_present(attrs, "textColor", &normalize_scales_with_text_color/1, "text_color")
      |> put_if_present(attrs, "value_format", &normalize_scales_with_value_format_string/1)
      |> put_if_present(attrs, "valueFormat", &normalize_scales_with_value_format_string/1, "value_format")

    row
    |> ScalesWithOption.update_changeset(updates)
    |> Repo.update()
  end

  def delete_scales_with_option(%ScalesWithOption{} = row) do
    used =
      Repo.exists?(
        from p in ChampionSkillParam,
          where: p.scales_with == ^row.id
      )

    if used do
      {:error, :in_use}
    else
      Repo.delete(row)
    end
  end

  def get_champion(id) when is_binary(id) do
    Champion
    |> where([c], c.id == ^id)
    |> preload(^champion_preloads())
    |> Repo.one()
  end

  defp champion_preloads do
    [
      :role_type_row,
      champion_traits:
        from(ct in ChampionTrait,
          order_by: [asc: ct.sort_order, asc: ct.trait_id],
          preload: [:trait]
        ),
      star_stats: from(s in ChampionStarStat, order_by: [asc: s.stars]),
      # Không dùng query tùy chỉnh trên ChampionSkillParam ở đây: Ecto có thể gộp sai FK
      # (tìm champion_id đã xóa). Thứ tự param sắp xếp trong Json.champion/1.
      champion_skills:
        from(s in ChampionSkill,
          order_by: [asc: s.sort_order, asc: s.id],
          preload: [:skill_params]
        )
    ]
  end

  @doc """
  Tạo tướng kèm tộc hệ (M:N), chỉ số theo sao, tham số kỹ năng.
  `attrs` dùng string keys: traits, starStats, skillParams (hoặc snake_case).
  """
  def create_champion(attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)
    trait_names = extract_trait_names(attrs)
    star_stats = extract_star_stats(attrs)
    skills = extract_skills_full(attrs)

    base =
      attrs
      |> Map.drop([
        "traits",
        "star_stats",
        "starStats",
        "skill_params",
        "skillParams",
        "skills"
      ])

    cond do
      trait_names == [] ->
        {:error, invalid_traits_changeset()}

      star_stats == [] ->
        {:error, invalid_star_stats_changeset()}

      skills == [] ->
        {:error, invalid_skills_changeset()}

      true ->
        first = hd(skills)

        base =
          base
          |> Map.put_new("content_version", 1)
          |> Map.put_new("version_id", "default")
          |> Map.put("skill_name", first.name)
          |> Map.put("skill_description_template", first.description_template)

        Multi.new()
        |> Multi.insert(:champion, Champion.create_changeset(%Champion{}, base))
        |> Multi.run(:traits, fn repo, %{champion: c} ->
          insert_champion_traits(repo, c.id, trait_names, c.version_id)
        end)
        |> Multi.run(:star_stats, fn repo, %{champion: c} ->
          insert_star_stats(repo, c.id, star_stats)
        end)
        |> Multi.run(:champion_skills, fn repo, %{champion: c} ->
          insert_champion_skills_with_params(repo, c.id, skills)
        end)
        |> Repo.transaction()
        |> normalize_multi_result(:champion)
    end
  end

  def update_champion(%Champion{} = champion, attrs) when is_map(attrs) do
    attrs = DescriptionParams.stringify_keys_map(attrs)
    trait_names = extract_trait_names_optional(attrs)
    star_stats = extract_star_stats_optional(attrs)
    skills_outcome = extract_skills_update_outcome(attrs)

    base =
      attrs
      |> Map.drop(["traits", "star_stats", "starStats", "skill_params", "skillParams", "skills"])
      |> Map.put("content_version", (champion.content_version || 1) + 1)

    base =
      case skills_outcome do
        {:full, list} when list != [] ->
          first = hd(list)

          base
          |> Map.put("skill_name", first.name)
          |> Map.put("skill_description_template", first.description_template)

        _ ->
          base
      end

    Multi.new()
    |> Multi.update(:champion, Champion.update_changeset(champion, base))
    |> Multi.run(:traits, fn repo, %{champion: c} ->
      if trait_names == :absent do
        {:ok, :skipped}
      else
        replace_champion_traits(repo, c.id, trait_names, c.version_id)
      end
    end)
    |> Multi.run(:star_stats, fn repo, %{champion: c} ->
      if star_stats == :absent do
        {:ok, :skipped}
      else
        replace_star_stats(repo, c.id, star_stats)
      end
    end)
    |> Multi.run(:champion_skills, fn repo, %{champion: c} ->
      case skills_outcome do
        :absent ->
          {:ok, :skipped}

        {:full, list} ->
          replace_champion_skills(repo, c.id, list)

        {:params_only, rows} ->
          replace_first_skill_params_only(repo, c.id, rows)
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

  defp insert_champion_traits(repo, champion_id, trait_names, version_id) do
    Enum.with_index(trait_names, 0)
    |> Enum.reduce_while({:ok, :ok}, fn {name, idx}, {:ok, _} ->
      with {:ok, trait} <- find_trait(repo, name, version_id),
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

  defp replace_champion_traits(repo, champion_id, trait_names, version_id) do
    repo.delete_all(from(ct in ChampionTrait, where: ct.champion_id == ^champion_id))

    if trait_names == [] do
      {:error, invalid_traits_changeset()}
    else
      insert_champion_traits(repo, champion_id, trait_names, version_id)
    end
  end

  defp find_trait(repo, name, version_id) when is_binary(name) do
    vid = normalize_version_id(version_id)
    id = trait_id_from_name(name)

    case repo.one(from(t in Trait, where: t.id == ^id and t.version_id == ^vid, limit: 1)) do
      %Trait{} = t ->
        {:ok, t}

      nil ->
        case repo.one(from(t in Trait, where: t.name == ^name and t.version_id == ^vid, limit: 1)) do
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

  defp insert_skill_params_for_skill(repo, champion_skill_id, rows) do
    Enum.reduce_while(rows, {:ok, :ok}, fn row, {:ok, _} ->
      row = Map.put(row, :champion_skill_id, champion_skill_id)

      case %ChampionSkillParam{}
           |> ChampionSkillParam.changeset(row)
           |> repo.insert() do
        {:ok, _} -> {:cont, {:ok, :ok}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp insert_champion_skills_with_params(repo, champion_id, skills) do
    skills = Enum.sort_by(skills, & &1.sort_order)

    Enum.reduce_while(skills, {:ok, :ok}, fn skill, {:ok, _} ->
      attrs = %{
        "champion_id" => champion_id,
        "sort_order" => skill.sort_order,
        "tab_label" => skill.tab_label,
        "name" => skill.name,
        "description_template" => skill.description_template
      }

      case %ChampionSkill{} |> ChampionSkill.changeset(attrs) |> repo.insert() do
        {:ok, sk} ->
          case insert_skill_params_for_skill(repo, sk.id, skill.params) do
            {:ok, _} -> {:cont, {:ok, :ok}}
            {:error, cs} -> {:halt, {:error, cs}}
          end

        {:error, cs} ->
          {:halt, {:error, cs}}
      end
    end)
  end

  defp replace_champion_skills(repo, champion_id, skills) do
    repo.delete_all(from(s in ChampionSkill, where: s.champion_id == ^champion_id))

    if skills == [] do
      {:error, invalid_skills_changeset()}
    else
      insert_champion_skills_with_params(repo, champion_id, skills)
    end
  end

  defp replace_first_skill_params_only(repo, champion_id, param_rows) do
    skill =
      repo.one(
        from(s in ChampionSkill,
          where: s.champion_id == ^champion_id,
          order_by: [asc: s.sort_order, asc: s.id],
          limit: 1
        )
      )

    case skill do
      nil ->
        {:error, invalid_skills_changeset()}

      s ->
        repo.delete_all(from(p in ChampionSkillParam, where: p.champion_skill_id == ^s.id))
        insert_skill_params_for_skill(repo, s.id, param_rows)
    end
  end

  defp extract_skills_full(attrs) do
    case Map.get(attrs, "skills") do
      list when is_list(list) and list != [] ->
        list
        |> Enum.with_index()
        |> Enum.map(fn {el, i} -> normalize_skill_block(el, i) end)

      _ ->
        params = extract_skill_params(attrs)

        name = attrs["skill_name"] |> to_string() |> String.trim()
        tmpl = attrs["skill_description_template"] |> to_string() |> String.trim()

        if name == "" or tmpl == "" do
          []
        else
          [
            %{
              tab_label: "Mặc định",
              name: name,
              description_template: tmpl,
              sort_order: 0,
              params: params
            }
          ]
        end
    end
  end

  defp extract_skills_update_outcome(attrs) do
    cond do
      Map.has_key?(attrs, "skills") ->
        list = Map.get(attrs, "skills") || []

        {:full,
         list
         |> Enum.with_index()
         |> Enum.map(fn {el, i} -> normalize_skill_block(el, i) end)}

      Map.has_key?(attrs, "skillParams") or Map.has_key?(attrs, "skill_params") ->
        {:params_only, extract_skill_params(attrs)}

      true ->
        :absent
    end
  end

  defp normalize_skill_block(el, default_idx) when is_map(el) do
    tab = Map.get(el, "tabLabel") || Map.get(el, "tab_label") || "Mặc định"
    tab = tab |> to_string() |> String.trim() |> then(fn t -> if t == "", do: "Mặc định", else: t end)

    name = Map.get(el, "name") |> to_string() |> String.trim()

    tmpl =
      (Map.get(el, "descriptionTemplate") || Map.get(el, "description_template") || "")
      |> to_string()
      |> String.trim()

    order = Map.get(el, "sortOrder") || Map.get(el, "sort_order")

    order =
      cond do
        is_integer(order) -> order
        true -> default_idx
      end

    params_raw = Map.get(el, "params") || []

    params =
      params_raw
      |> List.wrap()
      |> Enum.with_index()
      |> Enum.map(fn {p, j} -> normalize_skill_param_row(p, j) end)

    %{tab_label: tab, name: name, description_template: tmpl, sort_order: order, params: params}
  end

  defp invalid_skills_changeset do
    %ChampionSkill{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:base, "cần ít nhất một kỹ năng hợp lệ")
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

  defp normalize_skill_param_row(row, default_order) when is_map(row) do
    key = Map.get(row, "paramKey") || Map.get(row, "param_key")
    label = Map.get(row, "displayLabel") || Map.get(row, "display_label")
    vals = Map.get(row, "starValues") || Map.get(row, "star_values") || []
    vals = vals |> List.wrap() |> Enum.reject(&is_nil/1) |> Enum.map(&to_float_val/1)
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

  defp to_float_val(_), do: 0.0

  defp blank_to_nil(v) when v in [nil, ""], do: nil
  defp blank_to_nil(v), do: v

  defp put_description_params_if_present(acc, attrs) do
    if Map.has_key?(attrs, "description_params") or Map.has_key?(attrs, "descriptionParams") do
      raw = attrs["description_params"] || attrs["descriptionParams"] || []
      Map.put(acc, "description_params", DescriptionParams.normalize_list(raw))
    else
      acc
    end
  end

  defp put_if_present(acc, map, from_key, transform),
    do: put_if_present(acc, map, from_key, transform, from_key)

  defp put_if_present(acc, map, from_key, transform, to_key) do
    if Map.has_key?(map, from_key) do
      Map.put(acc, to_key, transform.(map[from_key]))
    else
      acc
    end
  end

  defp normalize_scales_with_text_color(nil), do: nil

  defp normalize_scales_with_text_color(v) do
    case v |> to_string() |> String.trim() do
      "" -> nil
      x -> x
    end
  end

  defp normalize_scales_with_value_format_string(v) do
    case v |> to_string() |> String.trim() |> String.downcase() do
      "" -> "flat"
      x -> x
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

end
