defmodule TftServer.Champions.ChampionSkill do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "champion_skills" do
    field :sort_order, :integer, default: 0
    field :tab_label, :string, default: "Mặc định"
    field :name, :string
    field :description_template, :string

    belongs_to :champion, TftServer.Champions.Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :string

    has_many :skill_params, TftServer.Champions.ChampionSkillParam,
      foreign_key: :champion_skill_id,
      references: :id

    timestamps()
  end

  def changeset(row \\ %__MODULE__{}, attrs) do
    row
    |> cast(attrs, [:champion_id, :sort_order, :tab_label, :name, :description_template])
    |> validate_required([:champion_id, :tab_label, :name, :description_template])
    |> validate_length(:tab_label, min: 1, max: 120)
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description_template, min: 1)
    |> foreign_key_constraint(:champion_id)
  end
end
