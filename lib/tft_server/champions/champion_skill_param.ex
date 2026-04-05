defmodule TftServer.Champions.ChampionSkillParam do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "champion_skill_params" do
    field :sort_order, :integer, default: 0
    field :param_key, :string
    field :display_label, :string
    field :star_values, {:array, :float}
    field :scales_with, :string

    belongs_to :champion, TftServer.Champions.Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :string

    timestamps()
  end

  @doc false
  def changeset(param \\ %__MODULE__{}, attrs) do
    param
    |> cast(attrs, [:champion_id, :param_key, :display_label, :star_values, :scales_with, :sort_order])
    |> validate_required([:champion_id, :param_key, :display_label, :star_values])
    |> validate_length(:param_key, min: 1, max: 64)
    |> validate_length(:display_label, min: 1, max: 120)
    |> validate_change(:star_values, fn :star_values, vals ->
      cond do
        not is_list(vals) ->
          [star_values: "phải là mảng"]

        length(vals) not in 3..4 ->
          [star_values: "phải có độ dài 3 hoặc 4 (theo sao)"]

        not Enum.all?(vals, &is_number/1) ->
          [star_values: "mỗi phần tử phải là số"]

        true ->
          []
      end
    end)
    |> normalize_scales_with()
    |> foreign_key_constraint(:champion_id)
    |> unique_constraint([:champion_id, :param_key])
  end

  defp normalize_scales_with(changeset) do
    case get_change(changeset, :scales_with) do
      "" -> put_change(changeset, :scales_with, nil)
      _ -> changeset
    end
  end
end
