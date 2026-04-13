defmodule TftServer.Seeds do
  @moduledoc false

  alias TftServer.Board.BoardBootstrap
  alias TftServer.Champions
  alias TftServer.Champions.{Champion, RoleType, Trait}
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, GameAugment, GameEncounter, MetaOverview, Version}
  alias TftServer.Repo
  alias TftServer.SeedData.Board, as: BoardData
  alias TftServer.SeedData.Champions, as: ChampionsData
  alias TftServer.SeedData.Compositions, as: CompositionsData
  alias TftServer.SeedData.Items, as: ItemsData

  def run do
    Repo.delete_all(Champion)
    Repo.delete_all(RoleType)
    Repo.delete_all(Trait)
    Repo.delete_all(BaseItem)
    Repo.delete_all(CombinedItem)
    Repo.delete_all(GameEncounter)
    Repo.delete_all(GameAugment)
    Repo.delete_all(Composition)
    Repo.delete_all(MetaOverview)
    Repo.delete_all(BoardBootstrap)
    Repo.delete_all(Version)

    insert_default_version()
    insert_seed_role_types()
    insert_seed_trait_defs()

    Enum.each(ChampionsData.rows(), fn row ->
      {:ok, _} = Champions.create_champion(row)
    end)
    insert_rows(BaseItem, ItemsData.base_rows())
    insert_rows(CombinedItem, ItemsData.combined_rows())
    insert_compositions(CompositionsData.compositions())
    insert_meta_overview()
    insert_board_bootstrap(BoardData.bootstrap_row())

    :ok
  end

  defp insert_rows(mod, rows) do
    Enum.each(rows, fn row ->
      struct(mod)
      |> mod.changeset(row)
      |> Repo.insert!()
    end)
  end

  defp insert_compositions(compositions) do
    Enum.each(compositions, fn comp ->
      traits = Map.fetch!(comp, :traits)
      champions = Map.fetch!(comp, :champions)

      attrs = Map.drop(comp, [:traits, :champions])

      composition =
        %Composition{}
        |> Composition.changeset(attrs)
        |> Repo.insert!()

      Enum.each(traits, fn t ->
        %CompositionTrait{}
        |> CompositionTrait.changeset(%{
          composition_id: composition.id,
          name: t.name,
          count: t.count
        })
        |> Repo.insert!()
      end)

      Enum.with_index(champions, 0)
      |> Enum.each(fn {ch, idx} ->
        %CompositionChampion{}
        |> CompositionChampion.changeset(%{
          composition_id: composition.id,
          sort_order: idx,
          name: ch.name,
          image_url: ch.image_url,
          items: Map.get(ch, :items, [])
        })
        |> Repo.insert!()
      end)
    end)
  end

  defp insert_meta_overview do
    %MetaOverview{}
    |> MetaOverview.changeset(%{
      id: "default",
      region: "NORTH AMERICA",
      updated_display: "2H AGO",
      patch_label: "Live Patch Analysis"
    })
    |> Repo.insert!()
  end

  # Tộc (origin) trong seed tướng — còn lại coi là hệ (class).
  @seed_origin_names MapSet.new([
    "Ionia",
    "Noxus",
    "Piltover",
    "Demacia",
    "Shadow Isles",
    "Ác Nữ"
  ])

  defp insert_seed_role_types do
    rows = [
      %{id: "fighter_ad", name: "Đấu Sĩ Vật Lý", color: "#C8AA6E", description: ""},
      %{id: "fighter_ap", name: "Đấu Sĩ Phép", color: "#7EC8E3", description: ""},
      %{id: "marksman", name: "Xạ Thủ Vật Lý", color: "#E6A04D", description: ""},
      %{id: "mage", name: "Thuật Sư Phép", color: "#9B59B6", description: ""},
      %{id: "role_unknown", name: "Chưa xác định", color: "#64748b", description: ""}
    ]

    Enum.each(rows, fn attrs ->
      %RoleType{}
      |> RoleType.changeset(attrs)
      |> Repo.insert!()
    end)
  end

  defp insert_seed_trait_defs do
    names =
      ChampionsData.rows()
      |> Enum.flat_map(&Map.get(&1, "traits", []))
      |> Enum.uniq()

    Enum.each(names, fn name ->
      kind = if MapSet.member?(@seed_origin_names, name), do: "origin", else: "class"

      {:ok, _} =
        Champions.create_trait_def(%{
          "name" => name,
          "kind" => kind,
          "version_id" => "default"
        })
    end)
  end

  defp insert_default_version do
    %Version{}
    |> Version.changeset(%{
      id: "default",
      label: "Default Set",
      is_active: true,
      notes: "Bản dữ liệu mặc định"
    })
    |> Repo.insert!()
  end

  defp insert_board_bootstrap(row) do
    %BoardBootstrap{}
    |> BoardBootstrap.changeset(row)
    |> Repo.insert!()
  end
end
