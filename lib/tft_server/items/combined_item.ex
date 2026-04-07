defmodule TftServer.Items.CombinedItem do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "combined_items" do
    field :name, :string
    field :description, :string
    field :components, {:array, :string}
    field :component_names, :string
    field :tier, :string
    field :tags, {:array, :string}
    field :image_url, :string
    field :stats, {:array, :map}
    field :version_id, :string, default: "default"

    timestamps()
  end

  @cast [
    :id,
    :name,
    :description,
    :components,
    :component_names,
    :tier,
    :tags,
    :image_url,
    :stats,
    :version_id
  ]

  def changeset(combined_item \\ %__MODULE__{}, attrs) do
    combined_item
    |> cast(attrs, @cast)
    |> validate_required([
      :id,
      :name,
      :description,
      :components,
      :component_names,
      :tags,
      :image_url,
      :stats,
      :version_id
    ])
  end
end
