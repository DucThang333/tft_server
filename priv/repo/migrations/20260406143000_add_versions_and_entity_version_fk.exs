defmodule TftServer.Repo.Migrations.AddVersionsAndEntityVersionFk do
  use Ecto.Migration

  def up do
    create table(:versions, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string, null: false
      add :is_active, :boolean, null: false, default: true
      add :notes, :text

      timestamps()
    end

    execute("""
    INSERT INTO versions (id, label, is_active, inserted_at, updated_at)
    VALUES ('default', 'Default Set', true, NOW(), NOW())
    ON CONFLICT (id) DO NOTHING
    """)

    alter table(:champions) do
      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"
    end

    alter table(:traits) do
      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"
    end

    alter table(:base_items) do
      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"
    end

    alter table(:combined_items) do
      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"
    end

    create index(:champions, [:version_id])
    create index(:traits, [:version_id])
    create index(:base_items, [:version_id])
    create index(:combined_items, [:version_id])
  end

  def down do
    drop index(:combined_items, [:version_id])
    drop index(:base_items, [:version_id])
    drop index(:traits, [:version_id])
    drop index(:champions, [:version_id])

    alter table(:combined_items) do
      remove :version_id
    end

    alter table(:base_items) do
      remove :version_id
    end

    alter table(:traits) do
      remove :version_id
    end

    alter table(:champions) do
      remove :version_id
    end

    drop table(:versions)
  end
end
