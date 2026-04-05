defmodule TftServer.Repo.Migrations.RemoveImageAltColumns do
  use Ecto.Migration

  def change do
    alter table(:champions) do
      remove :image_alt
    end

    alter table(:base_items) do
      remove :image_alt
    end

    alter table(:combined_items) do
      remove :image_alt
    end

    alter table(:compositions) do
      remove :background_image_alt
    end

    alter table(:composition_champions) do
      remove :image_alt
    end
  end
end
