defmodule TftServer.Meta.CompositionTrait do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "composition_traits" do
    belongs_to :composition, TftServer.Meta.Composition, foreign_key: :composition_id, type: :string
    field :name, :string
    field :count, :integer

    timestamps()
  end

  @cast [:composition_id, :name, :count]

  def changeset(composition_trait \\ %__MODULE__{}, attrs) do
    composition_trait
    |> cast(attrs, @cast)
    |> validate_required([:composition_id, :name, :count])
    |> foreign_key_constraint(:composition_id)
  end
end
