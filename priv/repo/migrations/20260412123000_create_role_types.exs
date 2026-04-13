defmodule TftServer.Repo.Migrations.CreateRoleTypes do
  use Ecto.Migration

  def up do
    create table(:role_types, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :color, :string, null: false, default: "#64748b"
      add :description, :text, null: false, default: ""

      timestamps()
    end

    create unique_index(:role_types, [:name])

    flush()

    execute """
    INSERT INTO role_types (id, name, color, description, inserted_at, updated_at)
    VALUES ('role_unknown', 'Chưa xác định', '#64748b', '', NOW(), NOW())
    """

    execute """
    INSERT INTO role_types (id, name, color, description, inserted_at, updated_at)
    SELECT DISTINCT ON (trim(x.r))
      'rt_' || md5(trim(x.r)),
      trim(x.r),
      '#64748b',
      '',
      NOW(),
      NOW()
    FROM (
      SELECT DISTINCT trim(role_type) AS r
      FROM champions
      WHERE trim(role_type) NOT IN ('', 'Chưa xác định')
    ) x
    ORDER BY trim(x.r)
    ON CONFLICT (id) DO NOTHING
    """

    execute """
    UPDATE champions
    SET role_type = CASE
      WHEN trim(role_type) = '' OR trim(role_type) = 'Chưa xác định' THEN 'role_unknown'
      ELSE 'rt_' || md5(trim(role_type))
    END
    """

    flush()

    alter table(:champions) do
      modify :role_type,
             references(:role_types, column: :id, type: :string, on_delete: :restrict),
             from: :string
    end
  end

  def down do
    execute "ALTER TABLE champions DROP CONSTRAINT IF EXISTS champions_role_type_fkey"

    drop table(:role_types)
  end
end
