defmodule Sorcery.SpecDb.SdHelpers do
  @moduledoc false

  @doc """
  Builds a map that can be passed into StreamData.fixed_map/1 to generate a map similar to a %#{__MODULE__}{}.
  """
  def fix_map(m, args \\ %{}) do
    fixed = Enum.reduce(m, %{}, fn {k, attr}, acc ->

      opts = Enum.reduce(attr, [], fn {k, v}, acc ->
        [{k, v} | acc]
      end)

      v = case attr do
        %{one_of: li} -> StreamData.one_of(li)
        %{t: :integer, min: min, max: max} -> StreamData.integer(min..max)
        %{t: :integer} -> StreamData.integer()
        %{t: :id} -> StreamData.integer()
        %{t: :float}   -> StreamData.float(opts)
        %{t: :string, min: min, max: max}  -> StreamData.binary(min_length: min, max_length: max)
        %{t: :string}  -> StreamData.binary(opts)
        %{t: :boolean} -> StreamData.boolean()
        %{t: :bool_array} -> StreamData.list_of(StreamData.boolean(), opts)
      end

      if Map.get(attr, :ignore) do
        acc
      else
        Map.put(acc, k, v)
      end

    end)
    
    Enum.reduce(args, fixed, fn {k, v}, acc ->
      Map.put(acc, k, StreamData.constant(v))
    end)
    |> Map.put(:id, StreamData.integer())
  end


  @doc """
  Generate a map similar to a %#{__MODULE__}{}
  """
  def gen(m, args \\ %{}) do
    fix_map(m, args)
    |> StreamData.fixed_map()
  end
end
