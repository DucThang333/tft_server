defmodule TftServer.Riot.RiotSnapshot do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "riot_snapshots" do
    field :endpoint, :string
    field :routing_value, :string
    field :resource_key, :string
    field :payload, :map

    timestamps(updated_at: false)
  end

  @cast [:endpoint, :routing_value, :resource_key, :payload]

  def changeset(snapshot \\ %__MODULE__{}, attrs) do
    snapshot
    |> cast(attrs, @cast)
    |> validate_required([:endpoint, :routing_value, :payload])
  end
end
