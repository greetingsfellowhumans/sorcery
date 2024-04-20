# {{{ WhereClause module
defmodule Sorcery.Query.WhereClause do
  defstruct [:lvar, :tk, :attr, :left, :right, :op, :other_lvar, :other_lvar_attr, :arg_name, :right_type]
  @type t :: %__MODULE__{
    lvar: atom(),
    tk: atom(),
    attr: atom(),
    left: any(),
    right: any(),
    op: atom(),
    other_lvar: nil | atom(),
    other_lvar_attr: nil | atom(),
    arg_name: nil | atom(),
    right_type: :literal | :lvar | :arg
  }

  def new([lvar, tk, clauses]) when is_list(clauses) do
    Enum.map(clauses, fn {attr, value} ->
      new([lvar, tk, attr, value])
    end)
  end
  def new([lvar, tk, attr, value]) do
    {op, right} = split_values(value)
    right_type = get_right_type(right)
    lvar? = references_lvar?(right)
    #op = if lvar?, do: :in, else: op
    {other_lvar, other_lvar_attr} = split_lvar(lvar?, right)
    arg_name =  arg_name(right)

    struct(__MODULE__, %{
      lvar: String.to_atom(lvar), tk: tk, attr: attr, right: right, op: op,
      other_lvar: other_lvar, other_lvar_attr: other_lvar_attr,
      arg_name: arg_name, right_type: right_type
    })
  end

  # {{{ private
  defp get_right_type("?" <> _), do: :lvar
  defp get_right_type(right) when is_atom(right) do
    case "#{right}" do
      "args_" <> _ -> :arg
      _ -> :literal
    end
  end
  defp get_right_type(_), do: :literal

  defp arg_name(right) when is_atom(right) do
    case "#{right}" do
      "args_" <> argname -> String.to_atom(argname)
      _ -> nil
    end
  end
  defp arg_name(_), do: nil

  defp references_lvar?("?" <> _), do: true
  defp references_lvar?(_), do: false

  defp split_values({op, right}), do: {op, right}
  defp split_values(right), do: {:==, right}

  defp split_lvar(false, _), do: {nil, nil}
  defp split_lvar(_, str) do
    case String.split(str, ".") do
      [root, attr] -> {String.to_atom(root), String.to_atom(attr)}
      [root] -> {String.to_atom(root), nil}
    end
  end
  # }}}

end
# }}}


defmodule Sorcery.Query do
  alias Sorcery.Query.WhereClause

  defstruct [
    :refstr,
    args: %{},
    where: [],
    find: %{},
  ] 
  @type t :: %__MODULE__{refstr: String.t(), where: list(Sorcery.Query.WhereClause), find: map()}

  def new(opts) do
    struct(__MODULE__, opts)
  end



  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @raw_struct Sorcery.Query.new(opts)


      def raw_struct(), do: @raw_struct

      def finds() do
        find =  @raw_struct.find
        Enum.reduce(find, %{}, fn 
          {str, :*}, acc -> Map.put(acc, String.to_atom(str), :*)
          {str, li}, acc ->
            li = [:id | li] |> Enum.uniq()
            Map.put(acc, String.to_atom(str), li)
        end)
      end

      def clauses() do
        for clause <- @raw_struct.where do
          Sorcery.Query.WhereClause.new(clause)
        end
        |> List.flatten()
      end
      def clauses(args) do
        Enum.map(clauses(), fn 
          %{right_type: :arg, arg_name: k} = clause -> 
            clause
            |> Map.put(:right, args[k])
            |> Map.put(:arg_name, nil)
            |> Map.put(:right_type, :literal)
          clause -> clause
        end)
      end

      @doc ~s"""
      When a Portal Server runs a Query, it must not only select the fields as described in :find, but it must also log some data for future Reverse Queries.
      The reverse_find is basically :find, but for reverse queries.

      Returns a list of %Sorcery.QueryResultLogPair{} structs.
      """
      def reverse_finds(), do: Sorcery.Query.ResultsLog.scan_for_pairs(clauses())

      def known_lvars(results) do
        reverse_finds()
        |> Enum.reduce(%{}, fn %{attr: attr, lvar: lvar}, acc ->
          values = results.data["#{lvar}"]
                   |> Enum.map(fn {_, entity} -> Map.get(entity, attr) end)
                   |> MapSet.new()
          acc = Map.put_new(acc, lvar, %{})
          put_in(acc, [lvar, attr], values)
        end)
      end

      def reverse_query(config_module, args) do
        Sorcery.Query.ReverseQuery.new(config_module, @raw_struct, args, clauses(args))
      end


    end
  end


end
