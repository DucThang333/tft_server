defmodule TftServer.Repo.Migrations.ChampionTraitsSkillsStarStats do
  use Ecto.Migration

  def up do
    create table(:traits, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:traits, [:name])

    create table(:champion_traits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sort_order, :integer, null: false, default: 0

      add :champion_id,
          references(:champions, column: :id, type: :string, on_delete: :delete_all),
          null: false

      add :trait_id, references(:traits, column: :id, type: :string, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create unique_index(:champion_traits, [:champion_id, :trait_id])
    create index(:champion_traits, [:trait_id])

    create table(:champion_star_stats, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :champion_id,
          references(:champions, column: :id, type: :string, on_delete: :delete_all),
          null: false

      add :stars, :integer, null: false
      add :hp, :integer, null: false
      add :mana_initial, :integer, null: false
      add :mana_max, :integer, null: false
      add :attack_damage, :integer, null: false
      add :ability_power, :integer, null: false
      add :armor, :integer, null: false
      add :magic_resist, :integer, null: false
      add :attack_speed, :float, null: false
      add :crit_chance, :float, null: false
      add :crit_damage, :float, null: false
      add :attack_range, :integer, null: false

      timestamps()
    end

    create unique_index(:champion_star_stats, [:champion_id, :stars])
    create index(:champion_star_stats, [:champion_id])

    create table(:champion_skill_params, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sort_order, :integer, null: false, default: 0

      add :champion_id,
          references(:champions, column: :id, type: :string, on_delete: :delete_all),
          null: false

      add :param_key, :string, null: false
      add :display_label, :string, null: false
      add :star_values, {:array, :float}, null: false
      add :scales_with, :string

      timestamps()
    end

    create unique_index(:champion_skill_params, [:champion_id, :param_key])
    create index(:champion_skill_params, [:champion_id])

    alter table(:champions) do
      add :role_type, :string
      add :content_version, :integer, null: false, default: 1
      add :skill_name, :string
      add :skill_description_template, :text
    end

    execute """
    INSERT INTO traits (id, name, inserted_at, updated_at)
    SELECT
      lower(regexp_replace(tr.t, '[^a-zA-Z0-9]+', '-', 'g')),
      tr.t,
      NOW(),
      NOW()
    FROM (
      SELECT DISTINCT trim(both from x.tname) AS t
      FROM champions ch,
      LATERAL unnest(ch.traits) AS x(tname)
      WHERE ch.traits IS NOT NULL AND array_length(ch.traits, 1) IS NOT NULL
    ) tr
    WHERE tr.t <> ''
    ON CONFLICT (id) DO NOTHING
    """

    execute """
    INSERT INTO champion_traits (id, champion_id, trait_id, sort_order, inserted_at, updated_at)
    SELECT gen_random_uuid(), ch.id, tr.id, (u.ord - 1)::integer, NOW(), NOW()
    FROM champions ch
    CROSS JOIN LATERAL unnest(ch.traits) WITH ORDINALITY AS u(tname, ord)
    INNER JOIN traits tr ON tr.name = trim(both from u.tname)
    WHERE ch.traits IS NOT NULL AND array_length(ch.traits, 1) IS NOT NULL
    """

    execute "UPDATE champions SET role_type = '' WHERE role_type IS NULL"
    execute "UPDATE champions SET skill_name = '' WHERE skill_name IS NULL"
    execute "UPDATE champions SET skill_description_template = '' WHERE skill_description_template IS NULL"

    alter table(:champions) do
      modify :role_type, :string, null: false, default: ""
      modify :skill_name, :string, null: false, default: ""
      modify :skill_description_template, :text, null: false, default: ""
    end

    alter table(:champions) do
      remove :traits
    end
  end

  def down do
    alter table(:champions) do
      add :traits, {:array, :string}, null: false, default: []
    end

    execute """
    UPDATE champions c
    SET traits = COALESCE(sub.names, ARRAY[]::varchar[])
    FROM (
      SELECT ct.champion_id,
             array_agg(t.name ORDER BY ct.sort_order)::varchar[] AS names
      FROM champion_traits ct
      INNER JOIN traits t ON t.id = ct.trait_id
      GROUP BY ct.champion_id
    ) sub
    WHERE c.id = sub.champion_id
    """

    alter table(:champions) do
      remove :skill_description_template
      remove :skill_name
      remove :content_version
      remove :role_type
    end

    drop table(:champion_skill_params)
    drop table(:champion_star_stats)
    drop table(:champion_traits)
    drop table(:traits)
  end
end
