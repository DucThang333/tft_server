defmodule TftServer.SeedData.Items do
  @moduledoc false

  @u "https://example.com/item.png"

  def base_rows do
    [
      %{id: "bf-sword", name: "B.F. Sword", short_name: "BF", stat: "AD", image_url: @u, utility: 0,
        offense: 3},
      %{id: "chain-vest", name: "Chain Vest", short_name: "Vest", stat: "Armor", image_url: @u,
        utility: 2, offense: 0},
      %{id: "giants-belt", name: "Giant's Belt", short_name: "Belt", stat: "HP", image_url: @u,
        utility: 2, offense: 0},
      %{id: "needlessly-large-rod", name: "Needlessly Large Rod", short_name: "Rod", stat: "AP",
        image_url: @u, utility: 0, offense: 3},
      %{id: "recurve-bow", name: "Recurve Bow", short_name: "Bow", stat: "AS", image_url: @u,
        utility: 0, offense: 2},
      %{id: "spatula", name: "Spatula", short_name: "Spat", stat: "Flex", image_url: @u, utility: 3,
        offense: 0}
    ]
  end

  def combined_rows do
    [
      %{
        id: "deathblade",
        name: "Deathblade",
        description: "Bonus AD.",
        components: ["bf-sword", "bf-sword"],
        component_names: "BF + BF",
        tier: "Tier 1",
        tags: ["offense"],
        image_url: @u,
        stats: [%{"label" => "AD", "value" => "+55"}]
      },
      %{
        id: "infinity-edge",
        name: "Infinity Edge",
        description: "Crit damage.",
        components: ["bf-sword", "recurve-bow"],
        component_names: "BF + Bow",
        tier: "",
        tags: ["crit"],
        image_url: @u,
        stats: [%{"label" => "Crit", "value" => "+35%"}]
      },
      %{
        id: "shield_with_heart",
        name: "Sterak's Gage",
        description: "Shield.",
        components: ["bf-sword", "giants-belt"],
        component_names: "BF + Belt",
        tier: "",
        tags: ["bruiser"],
        image_url: @u,
        stats: []
      },
      %{
        id: "bolt",
        name: "Statikk Shiv",
        description: "Chain lightning.",
        components: ["recurve-bow", "needlessly-large-rod"],
        component_names: "Bow + Rod",
        tier: "",
        tags: ["magic"],
        image_url: @u,
        stats: []
      }
    ]
  end
end
