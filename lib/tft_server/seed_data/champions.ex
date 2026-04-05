defmodule TftServer.SeedData.Champions do
  @moduledoc false

  @img "https://example.com/champion.png"

  def rows do
    [
      simple(
        "aurelius",
        "AURELIUS",
        5,
        "Đấu Sĩ Vật Lý",
        ["Ionia", "Invoker"],
        "Thiên Hỏa",
        "Gây {{damage}} sát thương phép.",
        [
          %{
            "paramKey" => "damage",
            "displayLabel" => "Sát thương",
            "starValues" => [180, 270, 1200],
            "scalesWith" => "ability_power"
          }
        ],
        900
      ),
      simple("briar", "BRIAR", 2, "Đấu Sĩ Phép", ["Noxus", "Slayer"], "Cuồng Huyết",
        "Cắn mục tiêu gây {{dmg}} sát thương.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [40, 60, 95]}],
        650
      ),
      simple("caitlyn", "CAITLYN", 1, "Xạ Thủ Vật Lý", ["Piltover", "Sniper"], "Headshot",
        "Bắn gây {{dmg}} sát thương vật lý.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [200, 300, 450]}],
        500
      ),
      simple("draven", "DRAVEN", 3, "Xạ Thủ Vật Lý", ["Noxus", "Executioner"], "Spinning Axe",
        "Ném rìu gây {{dmg}}.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [90, 135, 210]}],
        700
      ),
      simple("ezreal", "EZREAL", 4, "Thuật Sư Phép", ["Piltover", "Prodigy"], "Mystic Shot",
        "Pha lê gây {{dmg}} sát thương phép.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [100, 150, 240]}],
        550
      ),
      simple("fiora", "FIORA", 2, "Đấu Sĩ Vật Lý", ["Demacia", "Duelist"], "Lunge",
        "Đâm các mục tiêu gây {{dmg}}.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [55, 85, 130]}],
        600
      ),
      simple("gwen", "GWEN", 4, "Đấu Sĩ Phép", ["Shadow Isles", "Duelist"], "Snip Snip!",
        "Cắt kẻ địch gây {{dmg}} sát thương phép.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [70, 105, 160]}],
        720
      ),
      simple("hecarim", "HECARIM", 4, "Đấu Sĩ Vật Lý", ["Shadow Isles", "Juggernaut"], "Onslaught",
        "Lao vào gây {{dmg}}.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [80, 120, 400]}],
        800
      ),
      simple("irelia", "IRELIA", 5, "Đấu Sĩ Vật Lý", ["Ionia", "Duelist"], "Bladesurge",
        "Lướt gây {{dmg}} sát thương vật lý.",
        [%{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [120, 180, 800]}],
        850
      ),
      morgana_like_morrgan()
    ]
  end

  defp simple(id, name, cost, role, traits, skill_name, template, params, base_hp) do
    %{
      "id" => id,
      "name" => name,
      "cost" => cost,
      "role_type" => role,
      "traits" => traits,
      "skill_name" => skill_name,
      "skill_description_template" => template,
      "starStats" => triple_star(base_hp),
      "skillParams" => params,
      "image_url" => @img,
      "augment_state" => %{"linked" => [], "notes" => nil},
      "encounters" => []
    }
  end

  defp triple_star(base_hp) do
    Enum.map(1..3, fn s ->
      %{
        "stars" => s,
        "hp" => base_hp + s * 120,
        "manaInitial" => 0,
        "manaMax" => 60,
        "attackDamage" => 50 + s * 8,
        "abilityPower" => 100,
        "armor" => 35 + s * 2,
        "magicResist" => 35 + s * 2,
        "attackSpeed" => 0.65 + s * 0.04,
        "critChance" => 0.25,
        "critDamage" => 1.4,
        "attackRange" => 1
      }
    end)
  end

  defp morgana_like_morrgan do
    %{
      "id" => "morrgan",
      "name" => "MORRGAN",
      "cost" => 5,
      "role_type" => "Đấu Sĩ Phép",
      "traits" => ["Ác Nữ", "Mage"],
      "skill_name" => "Thế Hắc Ám",
      "skill_description_template" =>
        "Nội tại: Hồi máu bằng 20% sát thương Kỹ Năng. Kích hoạt: Biến hình 5 giây, nhận lá chắn {{shield}} và liên kết 3 kẻ địch gây {{dps_per_sec}} sát thương phép mỗi giây. Kết thúc: gây {{delayed_damage}} sát thương phép lên mục tiêu bị liên kết.",
      "starStats" => [
        %{
          "stars" => 1,
          "hp" => 800,
          "manaInitial" => 20,
          "manaMax" => 60,
          "attackDamage" => 45,
          "abilityPower" => 100,
          "armor" => 40,
          "magicResist" => 40,
          "attackSpeed" => 0.7,
          "critChance" => 0.25,
          "critDamage" => 1.4,
          "attackRange" => 2
        },
        %{
          "stars" => 2,
          "hp" => 1440,
          "manaInitial" => 20,
          "manaMax" => 60,
          "attackDamage" => 68,
          "abilityPower" => 100,
          "armor" => 40,
          "magicResist" => 40,
          "attackSpeed" => 0.7,
          "critChance" => 0.25,
          "critDamage" => 1.4,
          "attackRange" => 2
        },
        %{
          "stars" => 3,
          "hp" => 2592,
          "manaInitial" => 20,
          "manaMax" => 60,
          "attackDamage" => 101,
          "abilityPower" => 100,
          "armor" => 40,
          "magicResist" => 40,
          "attackSpeed" => 0.7,
          "critChance" => 0.25,
          "critDamage" => 1.4,
          "attackRange" => 2
        }
      ],
      "skillParams" => [
        %{
          "paramKey" => "shield",
          "displayLabel" => "Lá chắn",
          "starValues" => [250, 300, 4000],
          "scalesWith" => "ability_power"
        },
        %{
          "paramKey" => "dps_per_sec",
          "displayLabel" => "Sát thương mỗi giây",
          "starValues" => [55, 85, 1500],
          "scalesWith" => "ability_power"
        },
        %{
          "paramKey" => "delayed_damage",
          "displayLabel" => "Sát thương trì hoãn",
          "starValues" => [270, 405, 4000],
          "scalesWith" => "ability_power"
        }
      ],
      "image_url" => @img,
      "augment_state" => %{"linked" => [], "notes" => nil},
      "encounters" => []
    }
  end
end
