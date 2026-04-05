defmodule TftServerWeb.Api.V1.ItemController do
  use TftServerWeb, :controller

  alias TftServer.Items
  alias TftServerWeb.Api.V1.Json

  def base(conn, _params) do
    items =
      Items.list_base_items()
      |> Enum.map(&Json.base_item/1)

    json(conn, %{"baseItems" => items})
  end

  def combined(conn, _params) do
    items =
      Items.list_combined_items()
      |> Enum.map(&Json.combined_item/1)

    json(conn, %{"combinedItems" => items})
  end
end
