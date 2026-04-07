defmodule TftServer.Meta do
  @moduledoc false

  import Ecto.Query

  alias TftServer.Meta.{Composition, CompositionChampion, CompositionTrait, MetaOverview, Version}
  alias TftServer.Repo

  def list_compositions do
    traits_ordered = from(tt in CompositionTrait, order_by: tt.name)
    champions_ordered = from(cc in CompositionChampion, order_by: cc.sort_order)

    from(c in Composition,
      order_by: c.id,
      preload: [traits: ^traits_ordered, champions: ^champions_ordered]
    )
    |> Repo.all()
  end

  def get_overview do
    Repo.get_by(MetaOverview, id: "default")
  end

  def list_versions do
    from(v in Version, order_by: [desc: v.is_active, asc: v.id])
    |> Repo.all()
  end
end
