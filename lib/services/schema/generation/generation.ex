defmodule Sorcery.Schema.Generation do
  @moduledoc false

  def gen(full_fields, body \\ %{}) do
    id = case body do
      %{id: id} -> StreamData.constant(id)
      _ -> StreamData.positive_integer()
    end

    sd_map = Enum.reduce(full_fields, %{id: id}, fn {k, v}, acc -> 
      optional? = Map.get(v, :optional?)
      constant? = Map.has_key?(body, k)
      default = Map.get(v, :default)
      sd_field = v.__struct__.get_sd_field(v)

      field = cond do
        constant? -> StreamData.constant(body[k])
        default -> StreamData.constant(default)
        optional? -> StreamData.one_of([StreamData.constant(nil), sd_field])
        true -> sd_field
      end

      Map.put(acc, k, field)
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
