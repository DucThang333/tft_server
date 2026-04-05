defmodule TftServer.Champions.Trait do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "traits" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(trait \\ %__MODULE__{}, attrs) do
    trait
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1, max: 120)
    |> unique_constraint(:id)
    |> unique_constraint(:name)
  end
end
