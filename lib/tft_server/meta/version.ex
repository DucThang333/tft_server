defmodule TftServer.Meta.Version do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "versions" do
    field :label, :string
    field :is_active, :boolean, default: true
    field :notes, :string

    timestamps()
  end

  @cast [:id, :label, :is_active, :notes]

  def changeset(version \\ %__MODULE__{}, attrs) do
    version
    |> cast(attrs, @cast)
    |> validate_required([:id, :label])
    |> validate_length(:label, min: 1, max: 200)
  end
end
