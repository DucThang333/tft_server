defmodule TftServer.Meta.MetaOverview do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "meta_overview" do
    field :region, :string
    field :updated_display, :string
    field :patch_label, :string

    timestamps()
  end

  @cast [:id, :region, :updated_display, :patch_label]

  def changeset(meta_overview \\ %__MODULE__{}, attrs) do
    meta_overview
    |> cast(attrs, @cast)
    |> validate_required([:id, :region, :updated_display, :patch_label])
  end
end
