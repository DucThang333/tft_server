defmodule TftServer.Champions.ChampionTrait do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "champion_traits" do
    field :sort_order, :integer, default: 0

    belongs_to :champion, TftServer.Champions.Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :string

    belongs_to :trait, TftServer.Champions.Trait,
      foreign_key: :trait_id,
      references: :id,
      type: :string

    timestamps()
  end

  @doc false
  def changeset(champion_trait \\ %__MODULE__{}, attrs) do
    champion_trait
    |> cast(attrs, [:champion_id, :trait_id, :sort_order])
    |> validate_required([:champion_id, :trait_id])
    |> foreign_key_constraint(:champion_id)
    |> foreign_key_constraint(:trait_id)
    |> unique_constraint([:champion_id, :trait_id])
  end
end
