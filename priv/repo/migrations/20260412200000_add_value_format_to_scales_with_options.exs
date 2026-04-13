defmodule TftServer.Repo.Migrations.AddValueFormatToScalesWithOptions do
  use Ecto.Migration

  def up do
    alter table(:scales_with_options) do
      add :value_format, :string, null: false, default: "flat"
    end

    create constraint(:scales_with_options, :value_format_allowed,
             check: "value_format IN ('flat', 'percent')")
  end

  def down do
    drop constraint(:scales_with_options, :value_format_allowed)

    alter table(:scales_with_options) do
      remove :value_format
    end
  end
end
