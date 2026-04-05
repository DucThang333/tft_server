defmodule TftServerWeb.Api.V1.ChampionController do
  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.Json

  def index(conn, _params) do
    champions =
      Champions.list_champions()
      |> Enum.map(&Json.champion/1)

    json(conn, %{"champions" => champions})
  end
end
