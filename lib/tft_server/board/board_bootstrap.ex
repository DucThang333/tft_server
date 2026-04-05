defmodule TftServer.Board.BoardBootstrap do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "board_bootstrap" do
    field :synergies, {:array, :map}
    field :board_champions, {:array, :map}
    field :tray_champions, {:array, :map}
    field :board_items, {:array, :map}

    timestamps()
  end

  @cast [:id, :synergies, :board_champions, :tray_champions, :board_items]

  def changeset(board_bootstrap \\ %__MODULE__{}, attrs) do
    board_bootstrap
    |> cast(attrs, @cast)
    |> validate_required([:id, :synergies, :board_champions, :tray_champions, :board_items])
  end
end
