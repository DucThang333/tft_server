defmodule TftServer.Champions.ChampionStarStat do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "champion_star_stats" do
    field :stars, :integer

    field :hp, :integer
    field :mana_initial, :integer
    field :mana_max, :integer
    field :attack_damage, :integer
    field :ability_power, :integer
    field :armor, :integer
    field :magic_resist, :integer
    field :attack_speed, :float
    field :crit_chance, :float
    field :crit_damage, :float
    field :attack_range, :integer

    belongs_to :champion, TftServer.Champions.Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :string

    timestamps()
  end

  @stars_min 1
  @stars_max 4

  @doc false
  def changeset(stat \\ %__MODULE__{}, attrs) do
    stat
    |> cast(attrs, [
      :champion_id,
      :stars,
      :hp,
      :mana_initial,
      :mana_max,
      :attack_damage,
      :ability_power,
      :armor,
      :magic_resist,
      :attack_speed,
      :crit_chance,
      :crit_damage,
      :attack_range
    ])
    |> validate_required([
      :champion_id,
      :stars,
      :hp,
      :mana_initial,
      :mana_max,
      :attack_damage,
      :ability_power,
      :armor,
      :magic_resist,
      :attack_speed,
      :crit_chance,
      :crit_damage,
      :attack_range
    ])
    |> validate_number(:stars, greater_than_or_equal_to: @stars_min, less_than_or_equal_to: @stars_max)
    |> validate_number(:hp, greater_than_or_equal_to: 0)
    |> validate_number(:mana_max, greater_than_or_equal_to: 0)
    |> validate_number(:mana_initial, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:champion_id)
    |> unique_constraint([:champion_id, :stars])
  end
end
