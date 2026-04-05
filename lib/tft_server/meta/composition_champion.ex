defmodule TftServer.Meta.CompositionChampion do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "composition_champions" do
    belongs_to :composition, TftServer.Meta.Composition, foreign_key: :composition_id, type: :string
    field :sort_order, :integer
    field :name, :string
    field :image_url, :string
    field :items, {:array, :string}

    timestamps()
  end

  @cast [:composition_id, :sort_order, :name, :image_url, :items]

  def changeset(composition_champion \\ %__MODULE__{}, attrs) do
    composition_champion
    |> cast(attrs, @cast)
    |> validate_required([:composition_id, :sort_order, :name, :image_url, :items])
    |> foreign_key_constraint(:composition_id)
  end
end
