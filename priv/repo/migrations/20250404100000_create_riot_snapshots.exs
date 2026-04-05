defmodule TftServer.Repo.Migrations.CreateRiotSnapshots do
  use Ecto.Migration

  def change do
    create table(:riot_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :endpoint, :string, null: false
      add :routing_value, :string, null: false
      add :resource_key, :string
      add :payload, :map, null: false

      timestamps(updated_at: false)
    end

    create index(:riot_snapshots, [:endpoint])
    create index(:riot_snapshots, [:inserted_at])
  end
end
