defmodule TftServer.Seeds do
  @moduledoc false

  alias TftServer.Board.BoardBootstrap
  alias TftServer.Champions
  alias TftServer.Champions.{Champion, Trait}
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, MetaOverview, Version}
  alias TftServer.Repo
  alias TftServer.SeedData.Board, as: BoardData
  alias TftServer.SeedData.Champions, as: ChampionsData
  alias TftServer.SeedData.Compositions, as: CompositionsData
  alias TftServer.SeedData.Items, as: ItemsData

  def run do
    Repo.delete_all(Champion)
    Repo.delete_all(Trait)
    Repo.delete_all(BaseItem)
    Repo.delete_all(CombinedItem)
    Repo.delete_all(Composition)
    Repo.delete_all(MetaOverview)
    Repo.delete_all(BoardBootstrap)
    Repo.delete_all(Version)

    insert_default_version()

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
