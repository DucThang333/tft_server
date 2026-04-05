defmodule TftServer.Repo.Migrations.AddChampionAugmentStateEncounters do
  use Ecto.Migration

  def change do
    alter table(:champions) do
      add :augment_state, :jsonb,
        null: false,
        default: fragment(~s|'{"linked": [], "notes": null}'::jsonb|)

      add :encounters, :jsonb, null: false, default: fragment("'[]'::jsonb")
    end
  end
end
