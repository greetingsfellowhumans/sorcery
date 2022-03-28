defmodule Sorcery.SpecDb.CsHelpers do
  @moduledoc false


  defp builder(table, f, false) do
    Enum.reduce(table, [], fn {k, attr}, acc ->
      case attr do
        %{^f => true} -> [k | acc]
        _ -> acc
      end
    end)
  end
  defp builder(table, f, true) do
    Enum.reduce(table, [], fn {k, attr}, acc ->
      case attr do
        %{^f => false} -> acc
        _ -> [k | acc]
      end
    end)
  end

  # These just build lists of atoms for Ecto.Changeset cast and validate_required
  def get_cast_update(table) do
    default = true
    builder(table, :cast_update, default)
  end
  def get_cast_insert(table) do
    default = true
    builder(table, :cast_insert, default)
  end
  def get_require_update(table) do
    default = false
    builder(table, :require_update, default)
  end
  def get_require_insert(table) do
    default = true
    builder(table, :require_insert, default)
  end

  defp bump_string_max(string, %{max: max}), do: String.slice(string, 0..max)
  defp bump_string_max(string, _), do: string
  defp bump_number_max(num, %{max: max}), do: Kernel.min(max, num)
  defp bump_number_max(num, _), do: num
  defp bump_number_min(num, %{min: min}), do: Kernel.max(min, num)
  defp bump_number_min(num, _), do: num

  # Find values beyond their min/max, and coerce within the range if :bump true
  def bump(spec_table, attrs) do
    Enum.reduce(attrs, %{}, fn {k, v}, acc ->
      spec_field = Map.get(spec_table, k, %{})
      case spec_field do
        %{t: :string, bump: true} ->
          new_v = bump_string_max(v, spec_field)
          Map.put(acc, k, new_v)

        %{bump: true} ->
          new_v = bump_number_max(v, spec_field) |> bump_number_min(spec_field)
          Map.put(acc, k, new_v)

        _ -> Map.put(acc, k, v)
      end
    end)
  end

end
