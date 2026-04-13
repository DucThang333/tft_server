defmodule TftServer.Champions.Champion do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "champions" do
    field :name, :string
    field :cost, :integer

    belongs_to :role_type_row, TftServer.Champions.RoleType,
      foreign_key: :role_type,
      references: :id,
      type: :string
    field :content_version, :integer, default: 1
    field :skill_name, :string
    field :skill_description_template, :string
    field :image_url, :string
    field :version_id, :string, default: "default"
    # Trạng thái lõi: các augment gắn với tướng + ghi chú (JSON: %{"linked" => [...], "notes" => ...})
    field :augment_state, :map, default: %{"linked" => [], "notes" => nil}
    # Kỳ ngộ / portal liên quan (mảng object lưu trong JSONB)
    field :encounters, {:array, :map}, default: []

    has_many :champion_traits, TftServer.Champions.ChampionTrait, foreign_key: :champion_id
    has_many :star_stats, TftServer.Champions.ChampionStarStat, foreign_key: :champion_id

    has_many :champion_skills, TftServer.Champions.ChampionSkill, foreign_key: :champion_id

    timestamps()
  end

  @cast_base [
    :name,
    :cost,
    :role_type,
    :content_version,
    :skill_name,
    :skill_description_template,
    :image_url,
    :version_id,
    :augment_state,
    :encounters
  ]

  @cast_create [:id | @cast_base]

  @doc false
  def changeset(champion \\ %__MODULE__{}, attrs), do: create_changeset(champion, attrs)

  def create_changeset(champion \\ %__MODULE__{}, attrs) do
    champion
    |> cast(attrs, @cast_create)
    |> validate_required([
      :id,
      :name,
      :cost,
      :role_type,
      :skill_name,
      :skill_description_template,
      :image_url,
      :version_id
    ])
    |> validate_number(:cost, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:content_version, greater_than_or_equal_to: 1)
    |> validate_length(:role_type, min: 1)
    |> validate_length(:skill_name, min: 1)
    |> validate_length(:skill_description_template, min: 1)
    |> validate_augment_state_shape()
    |> validate_encounters_shape()
    |> unique_constraint(:id)
    |> foreign_key_constraint(:role_type)
  end

  def update_changeset(champion \\ %__MODULE__{}, attrs) do
    champion
    |> cast(attrs, @cast_base)
    |> validate_required([:name, :cost, :image_url])
    |> validate_number(:cost, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:content_version, greater_than_or_equal_to: 1)
    |> validate_if_changed_min_len(:role_type, 1)
    |> validate_if_changed_min_len(:skill_name, 1)
    |> validate_if_changed_min_len(:skill_description_template, 1)
    |> validate_augment_state_shape()
    |> validate_encounters_shape()
    |> foreign_key_constraint(:role_type)
  end

  defp validate_if_changed_min_len(changeset, field, min_len) do
    case get_change(changeset, field) do
      nil ->
        changeset

      v when is_binary(v) ->
        if byte_size(String.trim(v)) >= min_len do
          changeset
        else
          add_error(changeset, field, "không hợp lệ")
        end

      _ ->
        add_error(changeset, field, "không hợp lệ")
    end
  end

  defp validate_augment_state_shape(changeset) do
    validate_change(changeset, :augment_state, fn :augment_state, st ->
      if augment_state_valid?(st), do: [], else: [augment_state: "phải có linked là mảng object"]
    end)
  end

  defp augment_state_valid?(%{"linked" => linked}) when is_list(linked) do
    Enum.all?(linked, &is_map/1)
  end

  defp augment_state_valid?(_), do: false

  defp validate_encounters_shape(changeset) do
    validate_change(changeset, :encounters, fn :encounters, list ->
      if is_list(list) and Enum.all?(list, &is_map/1), do: [], else: [encounters: "phải là mảng object"]
    end)
  end
end
