defmodule Sorcery.SpecDb.SdHelpers do
  @moduledoc false

  @doc """
  Builds a map that can be passed into StreamData.fixed_map/1 to generate a map similar to a %#{__MODULE__}{}.
  """
  def fix_map(m, args \\ %{}) do
    fixed = Enum.reduce(m, %{}, fn {k, attr}, acc ->
      v = gen_column(attr)

      #opts = Enum.reduce(attr, [], fn {k, v}, acc ->
      #  [{k, v} | acc]
      #end)

      #v = case attr do
      #  %{one_of: li} -> StreamData.one_of(Enum.map(li, fn i -> 
      #      StreamData.constant(i)
      #  end))
      #  %{t: :string}  -> get_t_spec(:string, opts)
      #  %{t: :integer} -> get_t_spec(:integer, opts)
      #  %{t: :id} -> 
      #    opts = Keyword.put_new(opts, :min, 1)
      #    get_t_spec(:integer, opts)
      #  %{t: :float} -> get_t_spec(:float, opts)
      #  %{t: :boolean} -> get_t_spec(:boolean, opts)
      #  %{t: :atom} -> get_t_spec(:atom, opts)


      #  %{t: :list} -> get_t_spec(:list, opts)
      #end

      if Map.get(attr, :ignore) do
        acc
      else
        Map.put(acc, k, v)
      end

    end)
    
    # Merge in the args
    Enum.reduce(args, fixed, fn {k, v}, acc ->
      Map.put(acc, k, StreamData.constant(v))
    end)
    |> Map.put_new(:id, StreamData.integer(1..99999))
  end

  def gen_column(attr) do
    opts = Enum.reduce(attr, [], fn {k, v}, acc ->
      [{k, v} | acc]
    end)

    case attr do
      %{put: x} -> StreamData.constant(x)
      %{one_of: li} -> StreamData.one_of(Enum.map(li, fn i -> 
          StreamData.constant(i)
      end))
      %{t: :portals} -> gen_portals(opts[:tables])
      %{t: :string}  -> get_t_spec(:string, opts)
      %{t: :integer} -> get_t_spec(:integer, opts)
      %{t: :id} -> 
        opts = Keyword.put_new(opts, :min, 1)
        get_t_spec(:integer, opts)
      %{t: :float} -> get_t_spec(:float, opts)
      %{t: :boolean} -> get_t_spec(:boolean, opts)
      %{t: :atom} -> get_t_spec(:atom, opts)


      %{t: :list} -> get_t_spec(:list, opts)
    end
  end


  @doc """
  Generate a map similar to a %#{__MODULE__}{}
  """
  def gen(m, args \\ %{}) do
    fix_map(m, args)
    |> StreamData.fixed_map()
  end


  @doc """
  i.e. %{
    player: %{mod: Player, bodies: [%{id: 23}]}
    } |> gen_portals()

  will generate one Player (of id 23) in a portal.
  """
  def gen_portals(tables) do
    Enum.reduce(tables, %{}, fn {tk, %{mod: mod, bodies: bodies}}, acc ->

      table = Enum.reduce(bodies, %{}, fn args, table_acc ->
        id = Map.get(args, :id)
        Map.put(table_acc, id, mod.gen(args))
      end) |> StreamData.fixed_map()

      Map.put_new(acc, tk, table)

    end)
    |> StreamData.fixed_map()
  end


  defp get_t_spec(:string, opts)  do 
    max = Keyword.get(opts, :max)
    opts = if max, do: Keyword.put(opts, :max_length, max), else: opts

    min = Keyword.get(opts, :min)
    opts = if min, do: Keyword.put(opts, :min_length, min), else: opts

    cond do
      !!min and !!max ->
        StreamData.string(:ascii, opts)
        |> StreamData.filter(&(String.length(&1) >= min))
        |> StreamData.filter(&(String.length(&1) <= max))
      !!min ->
        StreamData.string(:ascii, opts)
        |> StreamData.filter(&(String.length(&1) >= min))
      !!max ->
        StreamData.string(:ascii, opts)
        |> StreamData.filter(&(String.length(&1) <= max))
      true -> StreamData.string(:ascii, opts)

    end
  end
  defp get_t_spec(:integer, opts) do 
    max = Keyword.get(opts, :max)
    min = Keyword.get(opts, :min, 0)
    cond do
      !!min and !!max -> StreamData.integer(min..max)
      !!min -> StreamData.integer(min..(min + 99999))
      !!max -> StreamData.integer((max - 99999)..max)
      true -> StreamData.integer()
    end
  end
  defp get_t_spec(:float, opts), do: StreamData.float(opts)
  defp get_t_spec(:boolean, _opts), do: StreamData.boolean()
  defp get_t_spec(:trinary, _opts), do: StreamData.one_of([
    StreamData.constant(true),
    StreamData.constant(false),
    StreamData.constant(nil),
  ])
  defp get_t_spec(:atom, _opts),    do: StreamData.atom(:alphanumeric)
  defp get_t_spec(:list, opts) do 
    max = Keyword.get(opts, :max)
    min = Keyword.get(opts, :min, 0)
    opts = if max, do: Keyword.put(opts, :max_length, max), else: opts
    opts = if min, do: Keyword.put(opts, :min_length, min), else: opts
    t = Keyword.get(opts, :coll_of)
    data = get_t_spec(t, opts)

    StreamData.list_of(data, opts)
  end

  defp get_t_spec(li, _opts) when is_list(li), do: StreamData.one_of(Enum.map(li, fn i -> StreamData.constant(i) end))

end
