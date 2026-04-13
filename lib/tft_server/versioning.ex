defmodule TftServer.Versioning do
  @moduledoc """
  Gom dữ liệu giữa các `versions` theo từng nhóm (tướng, tộc/hệ, trang bị, …).
  """

  import Ecto.Query

  alias TftServer.Champions.{Champion, Trait}
  alias TftServer.Items.{BaseItem, CombinedItem}
  alias TftServer.Meta.{GameAugment, GameEncounter, Version}
  alias TftServer.Repo

  @entity_keys ~w(champions traits baseItems combinedItems augments encounters)

  @doc """
  `entities`: danh sách khóa (chuỗi), ví dụ `["champions", "traits"]`.
  Mỗi khóa hợp lệ: cập nhật `version_id` từ `from` sang `to`.
  Trả về map đếm (kể cả nhóm không chọn = 0).
  """
  @spec migrate_data(String.t() | nil, String.t() | nil, [String.t()]) ::
          {:ok, map()}
          | {:error, :same_version | :unknown_target_version | :no_entities | term()}
  def migrate_data(from_id, to_id, entities) when is_list(entities) do
    from_v = normalize(from_id)
    to_v = normalize(to_id)
    allowed = MapSet.new(@entity_keys)

    normalized =
      entities
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.filter(&MapSet.member?(allowed, &1))
      |> Enum.uniq()

    cond do
      from_v == to_v ->
        {:error, :same_version}

      normalized == [] ->
        {:error, :no_entities}

      true ->
        case Repo.get(Version, to_v) do
          nil ->
            {:error, :unknown_target_version}

          _ ->
            base = zero_counts()

            Repo.transaction(fn ->
              Enum.reduce(normalized, base, fn key, acc ->
                {n, _} = migrate_entity(key, from_v, to_v)
                Map.put(acc, key, n)
              end)
            end)
            |> case do
              {:ok, counts} -> {:ok, counts}
              {:error, reason} -> {:error, reason}
            end
        end
    end
  end

  defp zero_counts do
    Map.new(@entity_keys, &{&1, 0})
  end

  defp migrate_entity("champions", from_v, to_v) do
    Repo.update_all(from(x in Champion, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp migrate_entity("traits", from_v, to_v) do
    Repo.update_all(from(x in Trait, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp migrate_entity("baseItems", from_v, to_v) do
    Repo.update_all(from(x in BaseItem, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp migrate_entity("combinedItems", from_v, to_v) do
    Repo.update_all(from(x in CombinedItem, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp migrate_entity("augments", from_v, to_v) do
    Repo.update_all(from(x in GameAugment, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp migrate_entity("encounters", from_v, to_v) do
    Repo.update_all(from(x in GameEncounter, where: x.version_id == ^from_v), set: [version_id: to_v])
  end

  defp normalize(nil), do: "default"
  defp normalize(""), do: "default"

  defp normalize(v) do
    case v |> to_string() |> String.trim() do
      "" -> "default"
      id -> id
    end
  end
end
