defmodule TftServer.Repo.Migrations.ChampionMultipleSkills do
  use Ecto.Migration

  def up do
    create table(:champion_skills, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :champion_id,
          references(:champions, column: :id, type: :string, on_delete: :delete_all),
          null: false

      add :sort_order, :integer, null: false, default: 0
      add :tab_label, :string, null: false, default: "Mặc định"
      add :name, :string, null: false
      add :description_template, :text, null: false

      timestamps()
    end

    create index(:champion_skills, [:champion_id])

    alter table(:champion_skill_params) do
      add :champion_skill_id, references(:champion_skills, type: :binary_id, on_delete: :delete_all)
    end

    execute("""
    INSERT INTO champion_skills (id, champion_id, sort_order, tab_label, name, description_template, inserted_at, updated_at)
    SELECT gen_random_uuid(), c.id, 0, 'Mặc định', c.skill_name, c.skill_description_template, NOW(), NOW()
    FROM champions c
    """)

    execute("""
    UPDATE champion_skill_params AS p
    SET champion_skill_id = s.id
    FROM champion_skills AS s
    WHERE s.champion_id = p.champion_id
    """)

    execute("ALTER TABLE champion_skill_params ALTER COLUMN champion_skill_id SET NOT NULL")

    drop unique_index(:champion_skill_params, [:champion_id, :param_key])
    drop index(:champion_skill_params, [:champion_id])

    alter table(:champion_skill_params) do
      remove :champion_id
    end

    create unique_index(:champion_skill_params, [:champion_skill_id, :param_key])
    create index(:champion_skill_params, [:champion_skill_id])
  end

  def down do
    alter table(:champion_skill_params) do
      add :champion_id, references(:champions, column: :id, type: :string, on_delete: :delete_all)
    end

    execute("""
    UPDATE champion_skill_params AS p
    SET champion_id = s.champion_id
    FROM champion_skills AS s
    WHERE s.id = p.champion_skill_id
    """)

    drop unique_index(:champion_skill_params, [:champion_skill_id, :param_key])
    drop index(:champion_skill_params, [:champion_skill_id])

    alter table(:champion_skill_params) do
      remove :champion_skill_id
    end

    create unique_index(:champion_skill_params, [:champion_id, :param_key])
    create index(:champion_skill_params, [:champion_id])

    drop table(:champion_skills)
  end
end
