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
    get "/meta/augments", MetaController, :augments
    get "/meta/encounters", MetaController, :encounters
    get "/meta/compositions", MetaController, :compositions
    get "/meta/overview", MetaController, :overview
    get "/meta/traits", MetaController, :traits
    get "/meta/versions", MetaController, :versions
    get "/meta/scales-with", MetaController, :scales_with
    get "/meta/role-types", MetaController, :role_types
    get "/board/bootstrap", BoardController, :bootstrap
    get "/riot/platform-status", RiotController, :platform_status

    post "/admin/champions", Admin.ChampionController, :create
    put "/admin/champions/:id", Admin.ChampionController, :update
    post "/admin/meta/traits", Admin.TraitController, :create
    put "/admin/meta/traits/:id", Admin.TraitController, :update
    delete "/admin/meta/traits/:id", Admin.TraitController, :delete
    post "/admin/meta/scales-with", Admin.ScalesWithOptionController, :create
    put "/admin/meta/scales-with/:id", Admin.ScalesWithOptionController, :update
    delete "/admin/meta/scales-with/:id", Admin.ScalesWithOptionController, :delete
    post "/admin/meta/role-types", Admin.RoleTypeController, :create
    put "/admin/meta/role-types/:id", Admin.RoleTypeController, :update
    delete "/admin/meta/role-types/:id", Admin.RoleTypeController, :delete
    post "/admin/items/combined", Admin.CombinedItemController, :create
    put "/admin/items/combined/:id", Admin.CombinedItemController, :update
    post "/admin/meta/augments", Admin.MetaAugmentController, :create
    put "/admin/meta/augments/:id", Admin.MetaAugmentController, :update
    post "/admin/meta/encounters", Admin.MetaEncounterController, :create
    put "/admin/meta/encounters/:id", Admin.MetaEncounterController, :update
    post "/admin/meta/migrate-version", Admin.VersionMigrateController, :create
  end
end
