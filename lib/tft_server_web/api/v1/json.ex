defmodule TftServerWeb.Api.V1.Json do
  @moduledoc false

  alias TftServer.Champions.{Champion, ChampionSkill, RoleType, ScalesWithOption, Trait}
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, GameAugment, GameEncounter, MetaOverview, Version}

  def champion(%Champion{} = c) do
    traits =
      (c.champion_traits || [])
      |> Enum.sort_by(&{&1.sort_order, &1.trait_id})
      |> Enum.map(fn ct ->
        %{"id" => ct.trait.id, "name" => ct.trait.name}
      end)

    skills_json =
      (c.champion_skills || [])
      |> Enum.sort_by(&{&1.sort_order, &1.id})
      |> Enum.map(fn %ChampionSkill{} = s ->
        params =
          (s.skill_params || [])
          |> Enum.sort_by(&{&1.sort_order, &1.param_key})
          |> Enum.map(&skill_param_json/1)

        %{
          "id" => s.id,
          "tabLabel" => s.tab_label,
          "sortOrder" => s.sort_order,
          "name" => s.name,
          "descriptionTemplate" => s.description_template,
          "params" => params
        }
      end)

    first_skill = List.first(skills_json)

    skill_compat =
      case first_skill do
        nil ->
          %{
            "name" => c.skill_name,
            "descriptionTemplate" => c.skill_description_template,
            "params" => []
          }

        f ->
          %{
            "name" => f["name"],
            "descriptionTemplate" => f["descriptionTemplate"],
            "params" => f["params"]
          }
      end

    star_stats = Enum.map(c.star_stats || [], &star_stat_json/1)

    {role_name, role_color} = role_type_display(c)

    %{
      "id" => c.id,
      "name" => c.name,
      "cost" => c.cost,
      "roleType" => c.role_type,
      "roleTypeName" => role_name,
      "roleTypeColor" => role_color,
      "contentVersion" => c.content_version,
      "versionId" => c.version_id,
      "traits" => traits,
      "skills" => skills_json,
      "skill" => skill_compat,
      "starStats" => star_stats,
      "imageUrl" => c.image_url,
      "augmentState" => champion_augment_state(c.augment_state),
      "encounters" => champion_encounters(c.encounters)
    }
  end

  defp skill_param_json(p) do
    base = %{
      "paramKey" => p.param_key,
      "displayLabel" => p.display_label,
      "starValues" => p.star_values,
      "sortOrder" => p.sort_order
    }

    if p.scales_with && p.scales_with != "",
      do: Map.put(base, "scalesWith", p.scales_with),
      else: base
  end

  defp star_stat_json(s) do
    %{
      "stars" => s.stars,
      "hp" => s.hp,
      "manaInitial" => s.mana_initial,
      "manaMax" => s.mana_max,
      "attackDamage" => s.attack_damage,
      "abilityPower" => s.ability_power,
      "armor" => s.armor,
      "magicResist" => s.magic_resist,
      "attackSpeed" => s.attack_speed,
      "critChance" => s.crit_chance,
      "critDamage" => s.crit_damage,
      "attackRange" => s.attack_range
    }
  end

  defp champion_augment_state(nil), do: %{"linked" => [], "notes" => nil}

  defp champion_augment_state(%{} = m) do
    linked = Map.get(m, "linked") || Map.get(m, :linked) || []
    notes = Map.get(m, "notes", Map.get(m, :notes))
    %{"linked" => linked, "notes" => notes}
  end

  defp champion_encounters(nil), do: []
  defp champion_encounters(list) when is_list(list), do: list
  defp champion_encounters(_), do: []

  defp role_type_display(%Champion{} = c) do
    case c.role_type_row do
      %RoleType{} = rt ->
        {rt.name || "", rt.color || ""}

      _ ->
        {"", ""}
    end
  end

  def game_role_type(%RoleType{} = r) do
    %{
      "id" => r.id,
      "name" => r.name,
      "color" => r.color || "#64748b",
      "description" => r.description || "",
      "descriptionParams" => object_description_params_json(r)
    }
  end

  def base_item(%BaseItem{} = i) do
    %{
      "id" => i.id,
      "name" => i.name,
      "shortName" => i.short_name,
      "stat" => i.stat,
      "imageUrl" => i.image_url,
      "versionId" => i.version_id,
      "utility" => i.utility,
      "offense" => i.offense
    }
  end

  def combined_item(%CombinedItem{} = i) do
    base = %{
      "id" => i.id,
      "name" => i.name,
      "description" => i.description,
      "components" => i.components,
      "componentNames" => i.component_names,
      "versionId" => i.version_id,
      "tags" => i.tags || [],
      "imageUrl" => i.image_url,
      "stats" => Enum.map(i.stats || [], &stat_line/1),
      "descriptionParams" => meta_description_params_json(i.description_params || [])
    }

    if i.tier && i.tier != "", do: Map.put(base, "tier", i.tier), else: base
  end

  def game_augment(%GameAugment{} = a) do
    %{
      "id" => a.id,
      "name" => a.name,
      "tier" => a.tier,
      "description" => a.description || "",
      "imageUrl" => a.image_url || "",
      "versionId" => a.version_id,
      "descriptionParams" => meta_description_params_json(a.description_params || [])
    }
  end

  def game_encounter(%GameEncounter{} = e) do
    %{
      "id" => e.id,
      "name" => e.name,
      "description" => e.description || "",
      "imageUrl" => e.image_url || "",
      "versionId" => e.version_id,
      "descriptionParams" => meta_description_params_json(e.description_params || [])
    }
  end

  defp stat_line(%{"label" => l, "value" => v}), do: %{"label" => l, "value" => v}
  defp stat_line(%{label: l, value: v}), do: %{"label" => l, "value" => v}

  def composition(%Composition{} = c) do
    traits = Enum.map(c.traits, &composition_trait/1)
    champions = Enum.map(c.champions, &composition_champion/1)

    base = %{
      "id" => c.id,
      "name" => c.name,
      "tier" => c.tier,
      "traits" => traits,
      "champions" => champions,
      "winRate" => c.win_rate,
      "top4Rate" => c.top4_rate,
      "difficulty" => c.difficulty,
      "performanceCurve" => c.performance_curve
    }

    base
    |> maybe_put("strategy", c.strategy)
    |> maybe_put("backgroundImageUrl", c.background_image_url)
  end

  defp composition_trait(%CompositionTrait{} = t) do
    %{"name" => t.name, "count" => t.count}
  end

  defp composition_champion(%CompositionChampion{} = cc) do
    base = %{
      "name" => cc.name,
      "imageUrl" => cc.image_url
    }

    items = cc.items || []

    if items == [] do
      base
    else
      Map.put(base, "items", items)
    end
  end
  def overview(nil) do
    %{
      "region" => "—",
      "updated" => "—",
      "patchLabel" => "—"
    }
  end
  def overview(%MetaOverview{} = o) do
    %{
      "region" => o.region,
      "updated" => o.updated_display,
      "patchLabel" => o.patch_label
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp meta_description_param_row_json(row) when is_map(row) do
    pk = row["param_key"] || row[:param_key] || ""
    label = row["display_label"] || row[:display_label] || ""
    sample = row["sample_value"] || row[:sample_value] || ""
    order = row["sort_order"] || row[:sort_order] || 0

    base = %{
      "paramKey" => to_string(pk),
      "displayLabel" => to_string(label),
      "sampleValue" => to_string(sample),
      "sortOrder" => order
    }

    sw = row["scales_with"] || row[:scales_with]

    if sw && to_string(sw) != "",
      do: Map.put(base, "scalesWith", to_string(sw)),
      else: base
  end

  defp meta_description_params_json(list) when is_list(list) do
    list
    |> Enum.sort_by(fn row ->
      order = row["sort_order"] || row[:sort_order] || 0
      pk = row["param_key"] || row[:param_key] || ""
      {order, pk}
    end)
    |> Enum.map(&meta_description_param_row_json/1)
  end

  defp meta_description_params_json(_), do: []

  # Map.get: avoids KeyError if an older release omitted `description_params` on the schema
  # while DB rows / newer JSON paths still expect this field.
  defp object_description_params_json(%_{} = o) do
    meta_description_params_json(Map.get(o, :description_params, []) || [])
  end

  def game_trait_def(%Trait{} = t) do
    kind = if t.kind == "class", do: "class", else: "origin"

    %{
      "id" => t.id,
      "name" => t.name,
      "kind" => kind,
      "description" => t.description || "",
      "iconUrl" => t.icon_url || "",
      "versionId" => t.version_id,
      "descriptionParams" => meta_description_params_json(t.description_params || [])
    }
  end

  def version(%Version{} = v) do
    %{
      "value" => v.id,
      "label" => v.label,
      "isActive" => v.is_active,
      "notes" => v.notes || ""
    }
  end

  def scales_with_option(%ScalesWithOption{} = o) do
    vf = if o.value_format in ["flat", "percent"], do: o.value_format, else: "flat"

    base = %{
      "id" => o.id,
      "label" => o.label,
      "iconUrl" => o.icon_url || "",
      "valueFormat" => vf
    }

    case o.text_color do
      c when is_binary(c) and c != "" -> Map.put(base, "textColor", c)
      _ -> base
    end
  end
end
