defmodule TftServer.Repo.Migrations.CreateTftCore do
  use Ecto.Migration

  def change do
    create table(:champions, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :cost, :integer, null: false
      add :traits, {:array, :string}, null: false, default: []
      add :image_url, :text, null: false
      add :image_alt, :text, null: false

      timestamps()
    end

    create table(:base_items, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :short_name, :string, null: false
      add :stat, :string, null: false
      add :image_url, :text, null: false
      add :image_alt, :text, null: false
      add :utility, :integer, null: false
      add :offense, :integer, null: false

      timestamps()
    end

    create table(:combined_items, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :components, {:array, :string}, null: false
      add :component_names, :string, null: false
      add :tier, :string
      add :tags, {:array, :string}, null: false, default: []
      add :image_url, :text, null: false
      add :image_alt, :text, null: false
      add :stats, {:array, :map}, null: false, default: []

      timestamps()
    end

    create table(:compositions, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :tier, :string, null: false
      add :win_rate, :float, null: false
      add :top4_rate, :float, null: false
      add :difficulty, :integer, null: false
      add :strategy, :text
      add :performance_curve, {:array, :integer}, null: false, default: []
      add :background_image_url, :text
      add :background_image_alt, :text

      timestamps()
    end

    create table(:composition_traits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :composition_id, references(:compositions, column: :id, type: :string, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :count, :integer, null: false

      timestamps()
    end

    create index(:composition_traits, [:composition_id])

    create table(:composition_champions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :composition_id, references(:compositions, column: :id, type: :string, on_delete: :delete_all),
        null: false

      add :sort_order, :integer, null: false, default: 0
      add :name, :string, null: false
      add :image_url, :text, null: false
      add :image_alt, :text, null: false
      add :items, {:array, :string}, null: false, default: []

      timestamps()
    end

    create index(:composition_champions, [:composition_id])

    create table(:meta_overview, primary_key: false) do
      add :id, :string, primary_key: true
      add :region, :string, null: false
      add :updated_display, :string, null: false
      add :patch_label, :string, null: false

      timestamps()
    end

    create table(:board_bootstrap, primary_key: false) do
      add :id, :string, primary_key: true
      add :synergies, :jsonb, null: false, default: fragment("'[]'::jsonb")
      add :board_champions, :jsonb, null: false, default: fragment("'[]'::jsonb")
      add :tray_champions, :jsonb, null: false, default: fragment("'[]'::jsonb")
      add :board_items, :jsonb, null: false, default: fragment("'[]'::jsonb")

      timestamps()
    end
  end
end
