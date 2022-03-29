defmodule Sorcery.SpecDb.NormHelpers do
  _status = :wip

  @moduledoc """
  [] - Create test/domain/Sorcery.SpecDb.NormHelpers.exs
  [] - Write public fn heads (fill them out later)
  [] - Complete all docs
  [] - Complete all checkboxes, commit, and push..
  """

  use Norm

  def required_keys(m) do
    Enum.reduce(m, [], fn {k, attrs}, acc ->
      case attrs do
        required: false -> acc
        _ -> [k | acc]
      end
    end)
  end

  def build_schema(m) do
    schema(Enum.reduce(m, %{}, fn {k, attr}, acc ->
      v = case attr do
        %{one_of: li} -> one_of(Enum.map(li, fn i ->
          spec(fn value -> i == value end)
        end))
        %{t: :list, coll_of: t, length: l} -> coll_of(get_t_spec(t, attr), min_count: l, max_count: l)
        %{t: :list, coll_of: t} -> coll_of(get_t_spec(t, attr))
        %{t: :integer} -> get_t_spec(:integer, attr)
        %{t: :id} -> get_t_spec(:integer, attr)
        %{t: :boolean} -> get_t_spec(:boolean, attr)
        %{t: :string} -> get_t_spec(:string, attr)
        %{t: :float} -> get_t_spec(:float, attr)
      end
      Map.put(acc, k, v)
    end))
    |> selection(required_keys(m))
  end


  defp get_t_spec(:integer, %{min: min, max: max}), do: spec(is_integer() and fn i -> i in min..max end)
  defp get_t_spec(:integer, %{min: min}), do: spec(is_integer() and fn i -> i >= min end)
  defp get_t_spec(:integer, %{max: max}), do: spec(is_integer() and fn i -> i <= max end)
  defp get_t_spec(:integer, _), do: spec(is_integer())

  defp get_t_spec(:float, %{min: min, max: max}), do: spec(is_float() and fn i -> i >= min and i <= max end)
  defp get_t_spec(:float, %{min: min}), do: spec(is_float() and fn i -> i >= min end)
  defp get_t_spec(:float, %{max: max}), do: spec(is_float() and fn i -> i <= max end)
  defp get_t_spec(:float, _), do: spec(is_float())

  defp get_t_spec(:string, %{min: min, max: max}), do: spec(is_binary() and fn i -> String.length(i) in min..max end)
  defp get_t_spec(:string, %{min: min}), do: spec(is_binary() and fn i -> String.length(i) >= min end)
  defp get_t_spec(:string, %{max: max}), do: spec(is_binary() and fn i -> String.length(i) <= max end)
  defp get_t_spec(:string, _), do: spec(is_binary())


  defp get_t_spec(:boolean, _), do: spec(is_boolean())
  defp get_t_spec(:trinary, _), do: one_of([true, false, nil])
  defp get_t_spec(:atom, _), do: spec(is_atom())


end
