defmodule TftServer.DescriptionParams do
  @moduledoc false

  def stringify_keys_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} when is_binary(k) -> {k, v}
    end)
  end

  def normalize_list(raw) when is_list(raw) do
    raw
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      row = if is_map(row), do: stringify_keys_map(row), else: %{}
      normalize_row(row, i)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def normalize_list(_), do: []

  defp normalize_row(row, default_order) when is_map(row) do
    key = row["param_key"] || row["paramKey"]
    label = row["display_label"] || row["displayLabel"]
    sample = row["sample_value"] || row["sampleValue"] || ""
    sw = row["scales_with"] || row["scalesWith"]
    order = row["sort_order"] || row["sortOrder"]

    key = if key, do: to_string(key) |> String.trim(), else: nil
    label = if label, do: to_string(label) |> String.trim(), else: ""
    sample = to_string(sample)
    order = sort_order(order, default_order)

    if key not in [nil, ""] and label != "" do
      %{
        "param_key" => key,
        "display_label" => label,
        "sample_value" => sample,
        "scales_with" => blank_to_nil(sw && to_string(sw) |> String.trim()),
        "sort_order" => order
      }
    else
      nil
    end
  end

  defp normalize_row(_, _), do: nil

  defp sort_order(order, _fallback) when is_integer(order), do: order

  defp sort_order(order, fallback) when is_binary(order) do
    case Integer.parse(String.trim(order)) do
      {n, _} -> n
      _ -> fallback
    end
  end

  defp sort_order(_, fallback), do: fallback

  defp blank_to_nil(v) when v in [nil, ""], do: nil
  defp blank_to_nil(v), do: v
end
