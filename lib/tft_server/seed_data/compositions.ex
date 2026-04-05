defmodule TftServer.SeedData.Compositions do
  @moduledoc false

  @img "https://example.com/comp.png"

  def compositions do
    [
      %{
        id: "arcane-sentinel",
        name: "Arcane Sentinel",
        tier: "S",
        win_rate: 0.22,
        top4_rate: 0.58,
        difficulty: 3,
        strategy: "Stack Ryze with Archanist — portal tempo.",
        performance_curve: [1, 2, 3, 4, 5],
        background_image_url: @img,
        traits: [
          %{name: "Arcanist", count: 6},
          %{name: "Warden", count: 2}
        ],
        champions: [
          %{name: "Ryze", image_url: @img, items: ["shield_with_heart", "bolt"]},
          %{name: "Lux", image_url: @img, items: []}
        ]
      },
      %{
        id: "noxus-aggro",
        name: "Noxus Aggro",
        tier: "A",
        win_rate: 0.18,
        top4_rate: 0.52,
        difficulty: 2,
        strategy: "Early Noxus tempo.",
        performance_curve: [2, 2, 3, 4, 4],
        background_image_url: nil,
        traits: [%{name: "Noxus", count: 5}],
        champions: [%{name: "Darius", image_url: @img, items: ["deathblade"]}]
      },
      %{
        id: "ionia-blade",
        name: "Ionia Blades",
        tier: "B",
        win_rate: 0.15,
        top4_rate: 0.48,
        difficulty: 4,
        strategy: "Duelist pivot.",
        performance_curve: [3, 3, 3, 3, 3],
        background_image_url: nil,
        traits: [%{name: "Ionia", count: 4}, %{name: "Duelist", count: 4}],
        champions: [%{name: "Yone", image_url: @img, items: []}]
      }
    ]
  end
end
