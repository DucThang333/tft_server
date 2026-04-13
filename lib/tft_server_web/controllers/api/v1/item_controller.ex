defmodule TftServerWeb.Api.V1.ItemController do
  use TftServerWeb, :controller

  alias TftServer.Items
  alias TftServerWeb.Api.V1.{DataVersion, Json}

  def base(conn, _params) do
    vid = DataVersion.id(conn)

    items =
      Items.list_base_items(vid)
      |> Enum.map(&Json.base_item/1)

    json(conn, %{"baseItems" => items})
  end

  def combined(conn, _params) do
    vid = DataVersion.id(conn)

    items =
      Items.list_combined_items(vid)
      |> Enum.map(&Json.combined_item/1)

    json(conn, %{"combinedItems" => items})
  end
end
