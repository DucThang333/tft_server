defmodule TftServer.Champions.RoleType do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "role_types" do
    field :name, :string
    field :color, :string, default: "#64748b"
    field :description, :string, default: ""
    field :description_params, {:array, :map}, default: []

    timestamps()
  end

  @doc false
  def changeset(row \\ %__MODULE__{}, attrs) do
    row
    |> cast(attrs, [:id, :name, :color, :description, :description_params])
    |> validate_required([:id, :name])
    |> validate_length(:id, min: 1, max: 64)
    |> validate_length(:name, min: 1, max: 120)
    |> validate_length(:color, max: 32)
    |> validate_length(:description, max: 10_000)
    |> validate_format(:id, ~r/^[a-z][a-z0-9_]*$/,
      message: "chỉ a-z, số, gạch dưới; bắt đầu bằng chữ"
    )
    |> unique_constraint(:id)
    |> unique_constraint(:name)
  end

  def update_changeset(%__MODULE__{} = row, attrs) do
    row
    |> cast(attrs, [:name, :color, :description, :description_params])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 120)
    |> validate_length(:color, max: 32)
    |> validate_length(:description, max: 10_000)
    |> unique_constraint(:name)
  end
end
