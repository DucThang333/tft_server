defmodule TftServer.Meta.Composition do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "compositions" do
    field :name, :string
    field :tier, :string
    field :win_rate, :float
    field :top4_rate, :float
    field :difficulty, :integer
    field :strategy, :string
    field :performance_curve, {:array, :integer}
    field :background_image_url, :string

    has_many :traits, TftServer.Meta.CompositionTrait
    has_many :champions, TftServer.Meta.CompositionChampion

    timestamps()
  end

  @cast [
    :id,
    :name,
    :tier,
    :win_rate,
    :top4_rate,
    :difficulty,
    :strategy,
    :performance_curve,
    :background_image_url
  ]

  def changeset(composition \\ %__MODULE__{}, attrs) do
    composition
    |> cast(attrs, @cast)
    |> validate_required([
      :id,
      :name,
      :tier,
      :win_rate,
      :top4_rate,
      :difficulty,
      :performance_curve
    ])
  end
end
