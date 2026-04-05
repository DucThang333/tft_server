defmodule TftServer.Items.BaseItem do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "base_items" do
    field :name, :string
    field :short_name, :string
    field :stat, :string
    field :image_url, :string
    field :utility, :integer
    field :offense, :integer

    timestamps()
  end

  @cast [:id, :name, :short_name, :stat, :image_url, :utility, :offense]

  def changeset(base_item \\ %__MODULE__{}, attrs) do
    base_item
    |> cast(attrs, @cast)
    |> validate_required([
      :id,
      :name,
      :short_name,
      :stat,
      :image_url,
      :utility,
      :offense
    ])
  end
end
