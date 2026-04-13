defmodule TftServer.Champions.ChampionSkillParam do
  use Ecto.Schema

  import Ecto.Changeset

  alias TftServer.Repo
  alias TftServer.Champions.ScalesWithOption

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "champion_skill_params" do
    field :sort_order, :integer, default: 0
    field :param_key, :string
    field :display_label, :string
    field :star_values, {:array, :float}
    field :scales_with, :string

    belongs_to :champion_skill, TftServer.Champions.ChampionSkill,
      foreign_key: :champion_skill_id,
      references: :id,
      type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(param \\ %__MODULE__{}, attrs) do
    param
    |> cast(attrs, [:champion_skill_id, :param_key, :display_label, :star_values, :scales_with, :sort_order])
    |> validate_required([:champion_skill_id, :param_key, :display_label, :star_values])
    |> validate_length(:param_key, min: 1, max: 64)
    |> validate_length(:display_label, min: 1, max: 120)
    |> validate_change(:star_values, fn :star_values, vals ->
      cond do
        not is_list(vals) ->
          [star_values: "phải là mảng"]

        length(vals) not in 1..4 ->
          [star_values: "phải có từ 1 đến 4 phần tử (theo sao)"]

        not Enum.all?(vals, &is_number/1) ->
          [star_values: "mỗi phần tử phải là số"]

        true ->
          []
      end
    end)
    |> normalize_scales_with()
    |> validate_scales_with_option_exists()
    |> foreign_key_constraint(:champion_skill_id)
    |> unique_constraint([:champion_skill_id, :param_key])
  end

  defp normalize_scales_with(changeset) do
    case get_change(changeset, :scales_with) do
      "" -> put_change(changeset, :scales_with, nil)
      _ -> changeset
    end
  end

  defp validate_scales_with_option_exists(changeset) do
    id = get_field(changeset, :scales_with)

    cond do
      id in [nil, ""] ->
        changeset

      Repo.get(ScalesWithOption, id) ->
        changeset

      true ->
        add_error(
          changeset,
          :scales_with,
          "không tồn tại — tạo tại GET/POST /api/v1/meta/scales-with hoặc admin"
        )
    end
  end
end
