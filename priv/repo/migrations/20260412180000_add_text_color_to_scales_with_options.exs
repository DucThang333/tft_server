defmodule TftServer.Repo.Migrations.AddTextColorToScalesWithOptions do
  use Ecto.Migration

  def up do
    alter table(:scales_with_options) do
      add :text_color, :string, null: true
    end

    execute("""
    UPDATE scales_with_options SET text_color = '#E6A04D'
    WHERE id IN ('attack_damage', 'ad', 'bonus_ad', 'physical')
    """)

    execute("""
    UPDATE scales_with_options SET text_color = '#7EC8E3'
    WHERE id IN ('ability_power', 'ap', 'magic', 'spell', 'magic_resist', 'mr')
    """)
  end

  def down do
    alter table(:scales_with_options) do
      remove :text_color
    end
  end
end
