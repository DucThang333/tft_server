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
    field :description_params, {:array, :map}, default: []

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
    :version_id,
    :description_params
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
    |> validate_change(:components, fn :components, comps ->
      if is_list(comps) and length(comps) == 2, do: [], else: [components: "cần đúng 2 mã thành phần"]
    end)
    |> foreign_key_constraint(:version_id, name: "combined_items_version_id_fkey")
  end
end
