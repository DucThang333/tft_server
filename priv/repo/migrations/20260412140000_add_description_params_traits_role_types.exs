defmodule TftServer.Repo.Migrations.AddDescriptionParamsTraitsRoleTypes do
  use Ecto.Migration

  def up do
    alter table(:traits) do
      add :description_params, :jsonb, null: false, default: fragment("'[]'::jsonb")
    end

    alter table(:role_types) do
      add :description_params, :jsonb, null: false, default: fragment("'[]'::jsonb")
    end
  end

  def down do
    alter table(:traits) do
      remove :description_params
    end

    alter table(:role_types) do
      remove :description_params
    end
  end
end
