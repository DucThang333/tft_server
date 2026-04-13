defmodule TftServerWeb.Api.V1.IntegrationTest do
  use TftServerWeb.ConnCase, async: false

  alias TftServer.Meta.Version

  setup do
    TftServer.Seeds.run()

    for {name, kind} <- [{"Scholar", "class"}, {"Mystic", "class"}] do
      {:ok, _} =
        TftServer.Champions.create_trait_def(%{
          "name" => name,
          "kind" => kind,
          "version_id" => "default"
        })
    end

    :ok
  end

  test "GET /api/v1/champions", %{conn: conn} do
    conn = get(conn, "/api/v1/champions")
    assert %{"champions" => champs} = json_response(conn, 200)
    assert length(champs) == 10
    first = hd(champs)
    assert first["id"] == "aurelius"
    assert first["roleType"] == "fighter_ad"
    assert first["roleTypeName"] == "Đấu Sĩ Vật Lý"
    assert is_binary(first["roleTypeColor"])
    assert first["contentVersion"] == 1
    assert first["versionId"] == "default"
    assert is_list(first["traits"])
    assert %{"id" => _, "name" => _} = hd(first["traits"])
    assert length(first["starStats"]) == 3
    assert first["starStats"] |> hd() |> Map.fetch!("stars") == 1
    assert %{"name" => _, "descriptionTemplate" => _, "params" => _} = first["skill"]
    assert is_list(first["skills"])
    assert length(first["skills"]) >= 1
    assert %{"tabLabel" => _, "name" => _, "descriptionTemplate" => _, "params" => _} = hd(first["skills"])
    assert %{"linked" => [], "notes" => nil} = first["augmentState"]
    assert first["encounters"] == []
  end

  test "POST /api/v1/admin/champions creates champion with augmentState and encounters", %{conn: conn} do
    payload = %{
      "champion" => %{
        "id" => "test-archivist",
        "name" => "ARCHIVIST",
        "cost" => 3,
        "roleType" => "mage",
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
    assert length(created["skills"]) == 1
    assert hd(created["skills"])["name"] == "Lưu Trữ"
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
    assert is_list(deathblade["descriptionParams"])
    ie = Enum.find(items, &(&1["id"] == "infinity-edge"))
    refute Map.has_key?(ie, "tier")
  end

  test "GET /api/v1/meta/augments and /meta/encounters", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/augments")
    assert %{"augments" => []} = json_response(conn, 200)

    conn = get(conn, "/api/v1/meta/encounters")
    assert %{"encounters" => []} = json_response(conn, 200)
  end

  test "POST/PUT /api/v1/admin/items/combined with descriptionParams", %{conn: conn} do
    create_payload = %{
      "item" => %{
        "id" => "admin-test-combined",
        "name" => "Test Combined",
        "description" => "Bonus {{amt}}.",
        "components" => ["bf-sword", "chain-vest"],
        "componentNames" => "BF + Vest",
        "tags" => ["test"],
        "imageUrl" => "https://example.com/x.png",
        "stats" => [],
        "descriptionParams" => [
          %{"paramKey" => "amt", "displayLabel" => "Amount", "sampleValue" => "25"}
        ]
      }
    }

    conn = post(conn, "/api/v1/admin/items/combined", create_payload)
    assert %{"item" => created} = json_response(conn, 201)
    assert created["id"] == "admin-test-combined"
    assert hd(created["descriptionParams"])["paramKey"] == "amt"

    update_payload = %{"item" => %{"descriptionParams" => []}}
    conn = put(conn, "/api/v1/admin/items/combined/admin-test-combined", update_payload)
    assert %{"item" => updated} = json_response(conn, 200)
    assert updated["descriptionParams"] == []
  end

  test "POST/PUT /api/v1/admin/meta/augments", %{conn: conn} do
    create_payload = %{
      "augment" => %{
        "id" => "test_aug_meta",
        "name" => "Test Augment",
        "tier" => "gold",
        "description" => "Gain {{x}}.",
        "imageUrl" => "https://example.com/a.png",
        "descriptionParams" => [
          %{"paramKey" => "x", "displayLabel" => "X", "sampleValue" => "10", "scalesWith" => "ability_power"}
        ]
      }
    }

    conn = post(conn, "/api/v1/admin/meta/augments", create_payload)
    assert %{"augment" => a} = json_response(conn, 201)
    assert a["id"] == "test_aug_meta"
    assert a["tier"] == "gold"
    assert hd(a["descriptionParams"])["paramKey"] == "x"

    conn =
      put(conn, "/api/v1/admin/meta/augments/test_aug_meta", %{
        "augment" => %{"descriptionParams" => [], "description" => "Plain."}
      })

    assert %{"augment" => u} = json_response(conn, 200)
    assert u["descriptionParams"] == []
    assert u["description"] == "Plain."
  end

  test "POST/PUT /api/v1/admin/meta/encounters", %{conn: conn} do
    create_payload = %{
      "encounter" => %{
        "id" => "test_enc_meta",
        "name" => "Test Portal",
        "description" => "Reward {{gold}} gold.",
        "imageUrl" => "https://example.com/e.png",
        "descriptionParams" => [
          %{"paramKey" => "gold", "displayLabel" => "Vàng", "sampleValue" => "3"}
        ]
      }
    }

    conn = post(conn, "/api/v1/admin/meta/encounters", create_payload)
    assert %{"encounter" => e} = json_response(conn, 201)
    assert e["id"] == "test_enc_meta"
    assert hd(e["descriptionParams"])["paramKey"] == "gold"

    conn =
      put(conn, "/api/v1/admin/meta/encounters/test_enc_meta", %{
        "encounter" => %{"descriptionParams" => []}
      })

    assert %{"encounter" => u} = json_response(conn, 200)
    assert u["descriptionParams"] == []
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
             "versionId" => "default",
             "descriptionParams" => desc_params
           } = first
    assert k in ["origin", "class"]
    assert is_list(desc_params)
  end

  test "GET /api/v1/meta/versions", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/versions")
    assert %{"versions" => versions} = json_response(conn, 200)
    assert Enum.any?(versions, fn v -> v["value"] == "default" and is_binary(v["label"]) end)
  end

  test "GET /api/v1/meta/role-types", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/role-types")
    assert %{"roleTypes" => rows} = json_response(conn, 200)
    assert length(rows) >= 4
    mage = Enum.find(rows, &(&1["id"] == "mage"))
    assert mage["name"] == "Thuật Sư Phép"
    assert is_binary(mage["color"])
    assert is_list(mage["descriptionParams"])
  end

  test "POST/PUT/DELETE /api/v1/admin/meta/role-types", %{conn: conn} do
    create_payload = %{
      "roleType" => %{
        "id" => "test_role_xyz",
        "name" => "Vai trò test",
        "color" => "#ff00aa",
        "description" => "mô tả"
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/v1/admin/meta/role-types", Jason.encode!(create_payload))

    assert %{"roleType" => created} = json_response(conn, 201)
    assert created["id"] == "test_role_xyz"
    assert created["name"] == "Vai trò test"

    update_payload = %{
      "roleType" => %{
        "name" => "Đã đổi tên",
        "color" => "#00ff00",
        "description" => ""
      }
    }

    conn =
      conn
      |> recycle()
      |> put_req_header("content-type", "application/json")
      |> put("/api/v1/admin/meta/role-types/test_role_xyz", Jason.encode!(update_payload))
    assert %{"roleType" => updated} = json_response(conn, 200)
    assert updated["name"] == "Đã đổi tên"

    conn =
      conn
      |> recycle()
      |> delete("/api/v1/admin/meta/role-types/test_role_xyz")

    assert response(conn, 204)
  end

  test "GET /api/v1/meta/scales-with", %{conn: conn} do
    conn = get(conn, "/api/v1/meta/scales-with")
    assert %{"scalesWithOptions" => rows} = json_response(conn, 200)
    assert length(rows) >= 3
    ap = Enum.find(rows, &(&1["id"] == "ability_power"))
    assert is_binary(ap["label"])
    assert Map.has_key?(ap, "iconUrl")
    assert ap["textColor"] == "#7EC8E3"
    assert ap["valueFormat"] == "flat"
  end

  test "POST/PUT/DELETE /api/v1/admin/meta/scales-with", %{conn: conn} do
    create_payload = %{
      "scalesWithOption" => %{
        "id" => "test_scale_xyz",
        "label" => "Test scale",
        "iconUrl" => "https://example.com/i.png"
      }
    }

    conn = post(conn, "/api/v1/admin/meta/scales-with", create_payload)
    assert %{"scalesWithOption" => created} = json_response(conn, 201)
    assert created["id"] == "test_scale_xyz"
    assert created["label"] == "Test scale"
    assert created["valueFormat"] == "flat"

    update_payload = %{
      "scalesWithOption" => %{
        "label" => "Updated label",
        "iconUrl" => "",
        "textColor" => "#aabbcc",
        "valueFormat" => "percent"
      }
    }

    conn = put(conn, "/api/v1/admin/meta/scales-with/test_scale_xyz", update_payload)
    assert %{"scalesWithOption" => updated} = json_response(conn, 200)
    assert updated["label"] == "Updated label"
    assert updated["textColor"] == "#aabbcc"
    assert updated["valueFormat"] == "percent"

    conn = delete(conn, "/api/v1/admin/meta/scales-with/test_scale_xyz")
    assert response(conn, 204)
  end

  test "POST /api/v1/admin/champions rejects unknown scalesWith on skill param", %{conn: conn} do
    payload = %{
      "champion" => %{
        "id" => "bad-scale-champ",
        "name" => "BAD",
        "cost" => 1,
        "roleType" => "mage",
        "traits" => ["Scholar", "Mystic"],
        "skillName" => "S",
        "skillDescriptionTemplate" => "{{x}}",
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
          %{
            "paramKey" => "x",
            "displayLabel" => "X",
            "starValues" => [100, 150, 900],
            "scalesWith" => "not_a_real_scale_id_ever"
          }
        ],
        "imageUrl" => "https://example.com/a.png"
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/v1/admin/champions", Jason.encode!(payload))

    assert json_response(conn, 422)
  end

  test "POST/PUT/DELETE /api/v1/admin/meta/traits", %{conn: conn} do
    create_payload = %{
      "trait" => %{
        "id" => "test-warden",
        "name" => "Test Warden",
        "kind" => "class",
        "description" => "Gây {{dmg}} sát thương.",
        "iconUrl" => "https://example.com/trait.png",
        "descriptionParams" => [
          %{
            "paramKey" => "dmg",
            "displayLabel" => "Sát thương",
            "sampleValue" => "100",
            "scalesWith" => "ability_power"
          }
        ]
      }
    }

    conn = post(conn, "/api/v1/admin/meta/traits", create_payload)
    assert %{"trait" => created} = json_response(conn, 201)
    assert created["id"] == "test-warden"
    assert created["kind"] == "class"
    assert [%{"paramKey" => "dmg", "displayLabel" => "Sát thương"} | _] = created["descriptionParams"]

    update_payload = %{
      "trait" => %{
        "name" => "Test Warden Updated",
        "description" => "Cập nhật mô tả",
        "descriptionParams" => []
      }
    }

    conn = put(conn, "/api/v1/admin/meta/traits/test-warden", update_payload)
    assert %{"trait" => updated} = json_response(conn, 200)
    assert updated["name"] == "Test Warden Updated"
    assert updated["description"] == "Cập nhật mô tả"
    assert updated["kind"] == "class"
    assert updated["descriptionParams"] == []

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

  test "GET /api/v1/champions filters by versionId", %{conn: conn} do
    %Version{}
    |> Version.changeset(%{id: "patch-empty", label: "Trống", is_active: false})
    |> TftServer.Repo.insert!()

    conn =
      get(conn, "/api/v1/champions?" <> URI.encode_query(%{"versionId" => "patch-empty"}))

    assert %{"champions" => []} = json_response(conn, 200)
  end

  test "POST /api/v1/admin/meta/migrate-version moves version_id", %{conn: conn} do
    %Version{}
    |> Version.changeset(%{id: "patch-m", label: "M", is_active: false})
    |> TftServer.Repo.insert!()

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/admin/meta/migrate-version",
        Jason.encode!(%{
          "fromVersionId" => "default",
          "toVersionId" => "patch-m",
          "entities" => ["champions"]
        })
      )

    assert %{"ok" => true, "migrated" => m} = json_response(conn, 200)
    assert m["champions"] == 10
    assert m["traits"] == 0

    conn_def = get(conn, "/api/v1/champions?" <> URI.encode_query(%{"versionId" => "default"}))
    assert %{"champions" => []} = json_response(conn_def, 200)

    conn_m = get(conn, "/api/v1/champions?" <> URI.encode_query(%{"versionId" => "patch-m"}))
    assert %{"champions" => ch} = json_response(conn_m, 200)
    assert length(ch) == 10
  end

  test "POST /api/v1/admin/meta/migrate-version rejects empty entities", %{conn: conn} do
    %Version{}
    |> Version.changeset(%{id: "patch-x", label: "X", is_active: false})
    |> TftServer.Repo.insert!()

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/admin/meta/migrate-version",
        Jason.encode!(%{
          "fromVersionId" => "default",
          "toVersionId" => "patch-x",
          "entities" => []
        })
      )

    assert %{"error" => "no_entities"} = json_response(conn, 422)
  end
end
