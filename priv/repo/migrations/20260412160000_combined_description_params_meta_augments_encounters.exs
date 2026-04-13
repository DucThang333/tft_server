defmodule TftServer.Repo.Migrations.CombinedDescriptionParamsMetaAugmentsEncounters do
  use Ecto.Migration

  def up do
    alter table(:combined_items) do
      add :description_params, :jsonb, null: false, default: fragment("'[]'::jsonb")
    end

    create table(:meta_augments, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :tier, :string, null: false
      add :description, :text, null: false, default: ""
      add :image_url, :text, null: false, default: ""
      add :description_params, :jsonb, null: false, default: fragment("'[]'::jsonb")

      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"

      timestamps()
    end

    create index(:meta_augments, [:version_id])

    create table(:meta_encounters, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false, default: ""
      add :image_url, :text, null: false, default: ""
      add :description_params, :jsonb, null: false, default: fragment("'[]'::jsonb")

      add :version_id, references(:versions, column: :id, type: :string, on_delete: :restrict),
        null: false,
        default: "default"

      timestamps()
    end

    create index(:meta_encounters, [:version_id])
  end

  def down do
    drop index(:meta_encounters, [:version_id])
    drop table(:meta_encounters)

    drop index(:meta_augments, [:version_id])
    drop table(:meta_augments)

    alter table(:combined_items) do
      remove :description_params
    end
  end
end
