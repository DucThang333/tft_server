defmodule TftServerWeb.Api.V1.BoardController do
  use TftServerWeb, :controller

  alias TftServer.Board

  def bootstrap(conn, _params) do
    b = Board.get_bootstrap()

    json(conn, %{
      "synergies" => b.synergies,
      "boardChampions" => b.board_champions,
      "trayChampions" => b.tray_champions,
      "boardItems" => b.board_items
    })
  end
end
