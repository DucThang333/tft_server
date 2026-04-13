defmodule TftServer.Meta.GameAugment do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "meta_augments" do
    field :name, :string
    field :tier, :string
    field :description, :string, default: ""
    field :image_url, :string, default: ""
    field :description_params, {:array, :map}, default: []
    field :version_id, :string, default: "default"

    timestamps()
  end

  def changeset(row \\ %__MODULE__{}, attrs) do
    row
    |> cast(attrs, [:id, :name, :tier, :description, :image_url, :description_params, :version_id])
    |> validate_required([:id, :name, :tier, :version_id])
    |> validate_length(:id, min: 1, max: 120)
    |> validate_length(:name, min: 1, max: 200)
    |> validate_inclusion(:tier, ["silver", "gold", "prismatic"])
    |> validate_length(:description, max: 10_000)
    |> validate_length(:image_url, max: 2000)
    |> foreign_key_constraint(:version_id, name: "meta_augments_version_id_fkey")
    |> unique_constraint(:id)
  end
end
