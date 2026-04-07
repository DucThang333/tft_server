defmodule TftServerWeb.Api.V1.IntegrationTest do
  use TftServerWeb.ConnCase, async: false

  setup do
    TftServer.Seeds.run()
    :ok
  end

  test "GET /api/v1/champions", %{conn: conn} do
    conn = get(conn, "/api/v1/champions")
    assert %{"champions" => champs} = json_response(conn, 200)
    assert length(champs) == 10
    first = hd(champs)
    assert first["id"] == "aurelius"
    assert first["contentVersion"] == 1
    assert first["versionId"] == "default"
    assert is_list(first["traits"])
    assert %{"id" => _, "name" => _} = hd(first["traits"])
    assert length(first["starStats"]) == 3
    assert first["starStats"] |> hd() |> Map.fetch!("stars") == 1
    assert %{"name" => _, "descriptionTemplate" => _, "params" => _} = first["skill"]
    assert %{"linked" => [], "notes" => nil} = first["augmentState"]
    assert first["encounters"] == []
  end

  test "POST /api/v1/admin/champions creates champion with augmentState and encounters", %{conn: conn} do
    payload = %{
      "champion" => %{
        "id" => "test-archivist",
        "name" => "ARCHIVIST",
        "cost" => 3,
        "roleType" => "Thuật Sư Phép",
        "traits" => ["Scholar", "Mystic"],
        "skillName" => "Lưu Trữ",
        "skillDescriptionTemplate" => "Gây {{dmg}} sát thương phép.",
        "starStats" => [
          %{
            "stars" => 1,
            "hp" => 500,
            "manaInitial" => 0,
            "manaMax" => 40,
            "attackDamage" => 40,
            "abilityPower" => 100,
            "armor" => 20,
            "magicResist" => 20,
            "attackSpeed" => 0.65,
            "critChance" => 0.25,
            "critDamage" => 1.4,
            "attackRange" => 3
          },
          %{
            "stars" => 2,
            "hp" => 900,
            "manaInitial" => 0,
            "manaMax" => 40,
            "attackDamage" => 60,
            "abilityPower" => 100,
            "armor" => 20,
            "magicResist" => 20,
            "attackSpeed" => 0.65,
            "critChance" => 0.25,
            "critDamage" => 1.4,
            "attackRange" => 3
          },
          %{
            "stars" => 3,
            "hp" => 1620,
            "manaInitial" => 0,
            "manaMax" => 40,
            "attackDamage" => 90,
            "abilityPower" => 100,
            "armor" => 20,
            "magicResist" => 20,
            "attackSpeed" => 0.65,
            "critChance" => 0.25,
            "critDamage" => 1.4,
            "attackRange" => 3
          }
        ],
        "skillParams" => [
          %{"paramKey" => "dmg", "displayLabel" => "Sát thương", "starValues" => [100, 150, 900]}
        ],
        "imageUrl" => "https://example.com/a.png",
        "augmentState" => %{
          "linked" => [%{"id" => "jeweled-lotus", "tier" => "gold", "name" => "Jeweled Lotus"}],
          "notes" => "uu tien carry"
        },
        "encounters" => [
          %{
            "id" => "portal-innovators",
            "name" => "Portal of Innovators",
            "description" => "demo",
            "imageUrl" => "https://example.com/p.png"
          }
        ]
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/v1/admin/champions", Jason.encode!(payload))

    assert %{"champion" => created} = json_response(conn, 201)
    assert created["id"] == "test-archivist"
    assert created["contentVersion"] == 1
    assert length(created["traits"]) == 2
    assert length(created["starStats"]) == 3
    assert length(created["skill"]["params"]) == 1
    assert length(created["augmentState"]["linked"]) == 1
    assert hd(created["augmentState"]["linked"])["id"] == "jeweled-lotus"
    assert length(created["encounters"]) == 1
  end

  test "PUT /api/v1/admin/champions/:id patches augmentState only", %{conn: conn} do
    payload = %{
      "champion" => %{
        "augmentState" => %{
          "linked" => [%{"id" => "x", "tier" => "silver", "name" => "Tiny Titans"}],
          "notes" => "only augment"
        }
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put("/api/v1/admin/champions/morrgan", Jason.encode!(payload))

    assert %{"champion" => updated} = json_response(conn, 200)
    assert updated["name"] == "MORRGAN"
    assert updated["contentVersion"] == 2
    assert hd(updated["augmentState"]["linked"])["id"] == "x"
    assert updated["augmentState"]["notes"] == "only augment"
  end

  test "GET /api/v1/items/base", %{conn: conn} do
    conn = get(conn, "/api/v1/items/base")
    assert %{"baseItems" => items} = json_response(conn, 200)
    assert length(items) == 6
  end

  test "GET /api/v1/items/combined", %{conn: conn} do
    conn = get(conn, "/api/v1/items/combined")
    assert %{"combinedItems" => items} = json_response(conn, 200)
    assert length(items) == 4
    deathblade = Enum.find(items, &(&1["id"] == "deathblade"))
    assert deathblade["tier"] == "Tier 1"
    ie = Enum.find(items, &(&1["id"] == "infinity-edge"))
    refute Map.has_key?(ie, "tier")
  end

  test "GET /api/v1/meta/compositions", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/compositions")
    assert %{"compositions" => comps} = json_response(conn, 200)
    assert length(comps) == 3
    arcane = Enum.find(comps, &(&1["id"] == "arcane-sentinel"))
    assert arcane["strategy"] =~ "Ryze"
    assert arcane["traits"] == [%{"name" => "Arcanist", "count" => 6}, %{"name" => "Warden", "count" => 2}]
    ryze = Enum.find(arcane["champions"], &(&1["name"] == "Ryze"))
    assert ryze["items"] == ["shield_with_heart", "bolt"]
  end

  test "GET /api/v1/meta/overview", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/overview")
    body = json_response(conn, 200)
    assert body["region"] == "NORTH AMERICA"
    assert body["updated"] == "2H AGO"
    assert body["patchLabel"] == "Live Patch Analysis"
  end

  test "GET /api/v1/meta/traits", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/traits")
    assert %{"traits" => traits} = json_response(conn, 200)
    assert length(traits) > 0
    first = hd(traits)
    assert %{
             "id" => _,
             "name" => _,
             "kind" => k,
             "description" => _,
             "iconUrl" => _,
             "versionId" => "default"
           } = first
    assert k in ["origin", "class"]
  end

  test "GET /api/v1/meta/versions", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/versions")
    assert %{"versions" => versions} = json_response(conn, 200)
    assert Enum.any?(versions, fn v -> v["value"] == "default" and is_binary(v["label"]) end)
  end

  test "POST/PUT/DELETE /api/v1/admin/meta/traits", %{conn: conn} do
    create_payload = %{
      "trait" => %{
        "id" => "test-warden",
        "name" => "Test Warden",
        "kind" => "class",
        "description" => "Trait dùng cho test",
        "iconUrl" => "https://example.com/trait.png"
      }
    }

    conn = post(conn, "/api/v1/admin/meta/traits", create_payload)
    assert %{"trait" => created} = json_response(conn, 201)
    assert created["id"] == "test-warden"
    assert created["kind"] == "class"

    update_payload = %{
      "trait" => %{
        "name" => "Test Warden Updated",
        "description" => "Cập nhật mô tả"
      }
    }

    conn = put(conn, "/api/v1/admin/meta/traits/test-warden", update_payload)
    assert %{"trait" => updated} = json_response(conn, 200)
    assert updated["name"] == "Test Warden Updated"
    assert updated["description"] == "Cập nhật mô tả"
    assert updated["kind"] == "class"

    conn = delete(conn, "/api/v1/admin/meta/traits/test-warden")
    assert response(conn, 204)
  end

  test "GET /api/v1/board/bootstrap", %{conn: conn} do
    conn = get(conn, "/api/v1/board/bootstrap")
    body = json_response(conn, 200)
    assert length(body["synergies"]) == 3
    assert length(body["boardChampions"]) == 3
    assert length(body["trayChampions"]) == 5
    assert length(body["boardItems"]) == 3
    assert hd(body["boardItems"])["id"] == "item-1"
  end
end
