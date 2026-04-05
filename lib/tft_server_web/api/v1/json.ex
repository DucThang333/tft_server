defmodule TftServerWeb.Api.V1.Json do
  @moduledoc false

  alias TftServer.Champions.Champion
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, MetaOverview}

  def champion(%Champion{} = c) do
    traits =
      (c.champion_traits || [])
      |> Enum.sort_by(&{&1.sort_order, &1.trait_id})
      |> Enum.map(fn ct ->
        %{"id" => ct.trait.id, "name" => ct.trait.name}
      end)

    skill_params = Enum.map(c.skill_params || [], &skill_param_json/1)
    star_stats = Enum.map(c.star_stats || [], &star_stat_json/1)

    %{
      "id" => c.id,
      "name" => c.name,
      "cost" => c.cost,
      "roleType" => c.role_type,
      "contentVersion" => c.content_version,
      "traits" => traits,
      "skill" => %{
        "name" => c.skill_name,
        "descriptionTemplate" => c.skill_description_template,
        "params" => skill_params
      },
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

  def base_item(%BaseItem{} = i) do
    %{
      "id" => i.id,
      "name" => i.name,
      "shortName" => i.short_name,
      "stat" => i.stat,
      "imageUrl" => i.image_url,
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
      "tags" => i.tags || [],
      "imageUrl" => i.image_url,
      "stats" => Enum.map(i.stats || [], &stat_line/1)
    }

    if i.tier && i.tier != "", do: Map.put(base, "tier", i.tier), else: base
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
end
