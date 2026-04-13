defmodule TftServer.Repo.Migrations.CreateScalesWithOptions do
  use Ecto.Migration

  def up do
    create table(:scales_with_options, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string, null: false
      add :icon_url, :string, null: false, default: ""

      timestamps()
    end

    execute("""
    INSERT INTO scales_with_options (id, label, icon_url, inserted_at, updated_at) VALUES
    ('ability_power', 'Sức mạnh phép (AP)', '', NOW(), NOW()),
    ('ap', 'AP (alias)', '', NOW(), NOW()),
    ('attack_damage', 'Sát thương vật lý (AD)', '', NOW(), NOW()),
    ('ad', 'AD (alias)', '', NOW(), NOW()),
    ('bonus_ad', 'AD cộng thêm', '', NOW(), NOW()),
    ('magic', 'Sát thương phép', '', NOW(), NOW()),
    ('spell', 'Phép (alias)', '', NOW(), NOW()),
    ('physical', 'Sát thương vật lý', '', NOW(), NOW()),
    ('health', 'Máu / hồi máu', '', NOW(), NOW()),
    ('max_health', 'Máu tối đa (alias)', '', NOW(), NOW()),
    ('bonus_health', 'Máu cộng thêm', '', NOW(), NOW()),
    ('shield', 'Lá chắn', '', NOW(), NOW()),
    ('max_hp', 'Máu tối đa', '', NOW(), NOW()),
    ('armor', 'Giáp', '', NOW(), NOW()),
    ('magic_resist', 'Kháng phép', '', NOW(), NOW()),
    ('mr', 'Kháng phép (alias)', '', NOW(), NOW()),
    ('count', 'Số lượng', '', NOW(), NOW()),
    ('stacks', 'Stack', '', NOW(), NOW()),
    ('units', 'Đơn vị', '', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING
    """)
  end

  def down do
    drop table(:scales_with_options)
  end
end
