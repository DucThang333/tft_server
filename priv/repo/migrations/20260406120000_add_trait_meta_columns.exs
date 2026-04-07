defmodule TftServer.Repo.Migrations.AddTraitMetaColumns do
  use Ecto.Migration

  def change do
    alter table(:traits) do
      add :kind, :string, null: false, default: "origin"
      add :description, :text, null: false, default: ""
      add :icon_url, :string, null: false, default: ""
    end
  end
end
