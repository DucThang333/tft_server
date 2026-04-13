defmodule TftServer.Champions.ScalesWithOption do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "scales_with_options" do
    field :label, :string
    field :icon_url, :string, default: ""
    # Màu chữ giá trị số trong mô tả (#RGB / #RRGGBB), optional.
    field :text_color, :string
    # "flat" = số thường; "percent" = thêm % sau chuỗi (vd. 100/150/225%).
    field :value_format, :string, default: "flat"

    timestamps()
  end

  @doc false
  def changeset(row \\ %__MODULE__{}, attrs) do
    row
    |> cast(attrs, [:id, :label, :icon_url, :text_color, :value_format])
    |> validate_required([:id, :label])
    |> validate_length(:id, min: 1, max: 64)
    |> validate_length(:label, min: 1, max: 200)
    |> validate_length(:icon_url, max: 2000)
    |> validate_length(:text_color, max: 16)
    |> normalize_text_color()
    |> normalize_value_format()
    |> validate_inclusion(:value_format, ["flat", "percent"])
    |> validate_format(:text_color, ~r/^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/,
      message: "phải là màu hex (#RGB hoặc #RRGGBB)"
    )
    |> validate_format(:id, ~r/^[a-z][a-z0-9_]*$/,
      message: "chỉ a-z, số, gạch dưới; bắt đầu bằng chữ"
    )
  end

  def update_changeset(%__MODULE__{} = row, attrs) do
    row
    |> cast(attrs, [:label, :icon_url, :text_color, :value_format])
    |> validate_required([:label])
    |> validate_length(:label, min: 1, max: 200)
    |> validate_length(:icon_url, max: 2000)
    |> validate_length(:text_color, max: 16)
    |> normalize_text_color()
    |> normalize_value_format()
    |> validate_inclusion(:value_format, ["flat", "percent"])
    |> validate_format(:text_color, ~r/^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/,
      message: "phải là màu hex (#RGB hoặc #RRGGBB)"
    )
  end

  defp normalize_text_color(changeset) do
    case get_change(changeset, :text_color) do
      nil ->
        changeset

      v when is_binary(v) ->
        t = String.trim(v)
        if t == "", do: put_change(changeset, :text_color, nil), else: put_change(changeset, :text_color, t)

      _ ->
        changeset
    end
  end

  defp normalize_value_format(changeset) do
    case get_change(changeset, :value_format) do
      nil ->
        changeset

      v when is_binary(v) ->
        t = String.trim(v) |> String.downcase()
        t = if t == "", do: "flat", else: t
        put_change(changeset, :value_format, t)

      _ ->
        changeset
    end
  end
end
