defmodule TftServerWeb.Api.V1.MetaController do
  use TftServerWeb, :controller

  alias TftServer.{Champions, Meta}
  alias TftServerWeb.Api.V1.{DataVersion, Json}

  def compositions(conn, _params) do
    comps =
      Meta.list_compositions()
      |> Enum.map(&Json.composition/1)

    json(conn, %{"compositions" => comps})
  end

  def overview(conn, _params) do
    json(conn, Json.overview(Meta.get_overview()))
  end

  def traits(conn, _params) do
    vid = DataVersion.id(conn)

    traits =
      Champions.list_trait_defs(vid)
      |> Enum.map(&Json.game_trait_def/1)

    json(conn, %{"traits" => traits})
  end

  def versions(conn, _params) do
    versions =
      Meta.list_versions()
      |> Enum.map(&Json.version/1)

    json(conn, %{"versions" => versions})
  end

  def scales_with(conn, _params) do
    rows =
      Champions.list_scales_with_options()
      |> Enum.map(&Json.scales_with_option/1)

    json(conn, %{"scalesWithOptions" => rows})
  end

  def role_types(conn, _params) do
    rows =
      Champions.list_role_types()
      |> Enum.map(&Json.game_role_type/1)

    json(conn, %{"roleTypes" => rows})
  end

  def augments(conn, _params) do
    vid = DataVersion.id(conn)

    rows =
      Meta.list_game_augments(vid)
      |> Enum.map(&Json.game_augment/1)

    json(conn, %{"augments" => rows})
  end

  def encounters(conn, _params) do
    vid = DataVersion.id(conn)

    rows =
      Meta.list_game_encounters(vid)
      |> Enum.map(&Json.game_encounter/1)

    json(conn, %{"encounters" => rows})
  end
end
