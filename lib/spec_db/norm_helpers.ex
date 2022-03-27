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
      v = case attr.t do
        :id -> spec(is_integer())
        :integer -> spec(is_integer())
        :string -> spec(is_binary())
        :binary -> spec(is_binary())
        :float -> spec(is_float())
        :bool_array -> coll_of(spec(is_boolean()))
        :integer_array -> coll_of(spec(is_integer()))
        :string_array -> coll_of(spec(is_binary()))
      end
      Map.put(acc, k, v)
    end))
    |> selection(required_keys(m))
  end


end
