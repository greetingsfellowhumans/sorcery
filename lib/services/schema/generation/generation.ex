defmodule Sorcery.Schema.Generation do
  @moduledoc false
  alias Sorcery.ReturnedEntities, as: RE

  def gen(full_fields) do
    sd_map = Enum.reduce(full_fields, %{id: StreamData.positive_integer()}, fn {k, v}, acc -> 
      sd_field = v.__struct__.get_sd_field(v)
      Map.put(acc, k, sd_field)
    end)
    StreamData.fixed_map(sd_map)
  end


  def gen_re(full_fields, n) do
    ids = 1..n
    fk_fields = Enum.reduce(full_fields, [], fn {k, %{t: t}}, acc -> if t == :fk, do: [t | acc], else: acc end)
    other_fields = Enum.reduce(full_fields, [], fn {k, %{t: t}}, acc -> if t != :fk, do: [k | acc], else: acc end)
    base_list = gen(full_fields) |> Enum.take(n)
  end


end
