defmodule Sorcery.Schema.Generation do
  @moduledoc false

  def gen(full_fields, body \\ %{}) do
    sd_map = Enum.reduce(full_fields, %{id: StreamData.positive_integer()}, fn {k, v}, acc -> 
      sd_field = if Map.has_key?(body, k) do
        StreamData.constant(body[k])
      else
        v.__struct__.get_sd_field(v)
      end
      Map.put(acc, k, sd_field)
    end)
    StreamData.fixed_map(sd_map)
  end


  # @TODO
  def gen_re(full_fields, n) do
    #ids = 1..n
    #fk_fields = Enum.reduce(full_fields, [], fn {k, %{t: t}}, acc -> if t == :fk, do: [t | acc], else: acc end)
    #other_fields = Enum.reduce(full_fields, [], fn {k, %{t: t}}, acc -> if t != :fk, do: [k | acc], else: acc end)
    gen(full_fields) |> Enum.take(n)
  end


end
