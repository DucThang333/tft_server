defmodule TftServerWeb.Api.V1.MetaController do
  use TftServerWeb, :controller

  alias TftServer.Meta
  alias TftServerWeb.Api.V1.Json

  def compositions(conn, _params) do
    comps =
      Meta.list_compositions()
      |> Enum.map(&Json.composition/1)

    json(conn, %{"compositions" => comps})
  end

  def overview(conn, _params) do
    json(conn, Json.overview(Meta.get_overview()))
  end
end
