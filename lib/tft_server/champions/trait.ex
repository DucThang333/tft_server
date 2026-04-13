defmodule TftServer.Champions.Trait do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "traits" do
    field :name, :string
    field :kind, :string, default: "origin"
    field :description, :string, default: ""
    field :description_params, {:array, :map}, default: []
    field :icon_url, :string, default: ""
    field :version_id, :string, default: "default"

    timestamps()
  end

  @doc false
  def changeset(trait \\ %__MODULE__{}, attrs) do
    trait
    |> cast(attrs, [:id, :name, :kind, :description, :description_params, :icon_url, :version_id])
    |> validate_required([:id, :name, :version_id])
    |> validate_length(:name, min: 1, max: 120)
    |> validate_inclusion(:kind, ["origin", "class"])
    |> validate_length(:description, max: 10_000)
    |> validate_length(:icon_url, max: 2000)
    |> unique_constraint(:id)
    |> unique_constraint(:name)
    |> foreign_key_constraint(:version_id, name: "traits_version_id_fkey")
  end
end
