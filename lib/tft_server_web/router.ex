defmodule TftServerWeb.Router do
  use TftServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", TftServerWeb.Api.V1, as: :api_v1 do
    pipe_through :api

    get "/health", HealthController, :show
    get "/champions", ChampionController, :index
    get "/items/base", ItemController, :base
    get "/items/combined", ItemController, :combined
    get "/meta/compositions", MetaController, :compositions
    get "/meta/overview", MetaController, :overview
    get "/board/bootstrap", BoardController, :bootstrap
    get "/riot/platform-status", RiotController, :platform_status

    post "/admin/champions", Admin.ChampionController, :create
    put "/admin/champions/:id", Admin.ChampionController, :update
  end
end
