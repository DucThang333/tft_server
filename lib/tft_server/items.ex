defmodule TftServer.Items do
  @moduledoc false

  import Ecto.Query

  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Repo

  def list_base_items do
    from(i in BaseItem, order_by: i.id) |> Repo.all()
  end

  def list_combined_items do
    from(i in CombinedItem, order_by: i.id) |> Repo.all()
  end
end
