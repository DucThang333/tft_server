defmodule TftServerWeb.Api.V1.ChampionController do
  use TftServerWeb, :controller

  alias TftServer.Champions
  alias TftServerWeb.Api.V1.{DataVersion, Json}

  def index(conn, _params) do
    vid = DataVersion.id(conn)

    champions =
      Champions.list_champions(vid)
      |> Enum.map(&Json.champion/1)

    json(conn, %{"champions" => champions})
  end
end
