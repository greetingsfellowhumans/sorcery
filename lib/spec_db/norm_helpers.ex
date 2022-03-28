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
        %{t: :list, coll_of: t} -> coll_of(get_t_spec(t))
        %{t: :id} -> spec(is_integer())
        %{t: :integer} -> spec(is_integer())
        %{t: :string} -> spec(is_binary())
        %{t: :binary} -> spec(is_binary())
        %{t: :float} -> spec(is_float())
        %{t: :bool_array} -> coll_of(spec(is_boolean()))
        %{t: :integer_array} -> coll_of(spec(is_integer()))
        %{t: :string_array} -> coll_of(spec(is_binary()))
      end
      Map.put(acc, k, v)
    end))
    |> selection(required_keys(m))
  end


  defp get_t_spec(:id), do: spec(is_integer())
  defp get_t_spec(:integer), do: spec(is_integer())
  defp get_t_spec(:string), do: spec(is_binary())
  defp get_t_spec(:binary), do: spec(is_binary())
  defp get_t_spec(:float), do: spec(is_float())
  defp get_t_spec(:bool), do: spec(is_boolean())
  defp get_t_spec(:boolean), do: spec(is_boolean())
  defp get_t_spec(:atom), do: spec(is_atom())


end
