# {{{ WhereClause module
defmodule Sorcery.Query.WhereClause do
  @moduledoc false
  defstruct [:lvar, :tk, :attr, :left, :right, :op, :other_lvar, :other_lvar_attr, :arg_name, :right_type]
  @type t :: %__MODULE__{
    lvar: binary(),
    tk: atom(),
    attr: atom(),
    left: any(),
    right: any(),
    op: atom(),
    other_lvar: nil | binary(),
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
  # {{{ moduledoc
  @moduledoc ~s"""
  A query module defines, in plain elixir data structures, the kind of data we want to watch for.

  The syntax takes some inspiration from Datalog, but with many differences as well.

  ```elixir
  defmodule Src.Queries.GetBattle do
  
    use Sorcery.Query, %{

      # Args will be passed in later when the query is called.
      args: %{
        player_id: :integer
      },

      # This is the meat of any query. Read it one row at a time.
      # Every row has either 3, 4, columns
      where: [
        # 4 column syntax:
        # [lvar,        tk,            attr,         value]
        #
        #
        # So we start with an lvar (or 'Logic Variable') called "?player"
        # It represents a set of entities with the Schema of :player
        # And we are filtering them such that ?player.id == args.player_id
        # The arg MUST be declared in the args map.
        [ "?player",    :player,       :id,          :args_player_id],

        # Now we make a new lvar called "?team"
        # See how it now references the previous lvar?
        # So we are filtering all teams such that team.id matches ANY ?player.team_id
        [ "?team",      :team,         :id,          "?player.team_id"],
        [ "?arena",     :battle_arena, :id,          "?team.location_id"],

        # This is not the same as ?team.
        # Its a new lvar using the same schema, but with a different set of filters
        # So we're getting all teams such that team.location_id == ?arena.id
        [ "?all_teams", :team,         :location_id, "?arena.id"],

        # Now we use the 3 column syntax, just to avoid repetition.
        # This could also be rewritten as two rows:
        # ["?all_players", :player, :team_id, "?all_teams.id"],
        # ["?all_players", :player, :health, {:>, 0}],
        [ "?all_players", :player, [
          {:team_id, "?all_teams.id"},
          {:health, {:>, 0}},
        ]],
        # Notice the value above {:>, 0}
        # By default, every value automatically expands under the hood to {:==, value}
        # But if you want to manually use an operator, you can.
        # Possible operators: :==, :!=, :>, :>=, :<, :<=, :in


        [ "?spells", :spell_instance, :player_id, "?all_players.id"],
        [ "?spell_types", :spell_type, :id, "?spells.type_id"],
      ],

      # Without a find map, the query returns no results.
      # We do not necessarily need all the lvars, nor all the fields
      # If we want all available fields, use :*
      # Otherwise pass in a list of specific ones. The :id attr is automatically added.
      find: %{
        "?arena" => :*,
        "?all_teams" => [:name, :location_id],
        "?all_players" => :*,
        "?spells" => :*,
        "?spell_types" => :*,
      }
    }

  end

  ```
  """
  # }}}


  alias Sorcery.Query.WhereClause

  defstruct [
    :refstr,
    args: %{},
    where: [],
    find: %{},
    lvar_tks: []
  ] 
  @type t :: %__MODULE__{refstr: String.t(), where: list(WhereClause), find: map()}

  @doc """
  If you have a map in the format of `%{tk => %{id => %{...entity...}}}`
  Then you can use it like a database and run the query against it.
  """
  defdelegate from_tk_map(query_mod, args, data), to: Sorcery.Query.TkQuery

  # CALLBACKS
  # {{{ clauses(args)
  @doc """
  Return a list of WhereClause structs for the Query module

  ## Examples
      iex> [clause1 | _] = Src.Queries.GetBattle.clauses(%{player_id: 1})
      iex> clause1
      %Sorcery.Query.WhereClause{lvar: :"?player", tk: :player, attr: :id, left: nil, right: 1, op: :==, other_lvar: nil, other_lvar_attr: nil, arg_name: nil, right_type: :literal}
  """
  @callback clauses(args :: map()) :: list(WhereClause)
  # }}}

  # {{{ new(opts)
  @doc false
  def new(opts) do
    ref = "#{inspect(make_ref())}"
    lvar_tks = Enum.map(opts[:where], fn [lvar, tk | _] -> {lvar, tk} end) |> Enum.uniq()

    opts =
      opts
      |> Map.put_new(:refstr, ref)
      |> Map.put_new(:lvar_tks, lvar_tks)

    struct(__MODULE__, opts)
  end
  # }}}

  # {{{ raw_struct
  @doc """
  Returns a Sorcery.Query struct.

  ## Examples
      iex> q = Src.Queries.GetBattle.raw_struct()
      iex> is_struct(q, Sorcery.Query)
      iex> q.find["?all_players"]
      :*
      iex> [clause1 | _] = q.where
      iex> clause1
      ["?player", :player, :id, :args_player_id]
      iex> Enum.at(q.lvar_tks, 3)
      {"?all_teams", :team}
  """
  @callback raw_struct() :: %__MODULE__{}
  # }}}

  # {{{ tks_affected()
  @doc """
  A unique list of all tks mentioned by this query.

  ## Examples
      iex> Src.Queries.GetBattle.tks_affected()
      [:player, :team, :battle_arena, :spell_instance, :spell_type]
  """
  @callback tks_affected() :: list(atom())
  # }}}

  # {{{ finds
  @doc """
  Returns the finds. This differs from raw_struct().finds because :id fields have been added.
  ## Examples
      iex> Src.Queries.GetBattle.finds()
      %{"?arena": :*, "?all_teams": [:location_id, :id, :name], "?all_players": :*, "?spells": :*, "?spell_types": :*}
  """
  @callback finds() :: map()
  # }}}

  # BEGIN USE
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Sorcery.Query
      @raw_struct Sorcery.Query.new(opts)

      @impl true
      def raw_struct(), do: @raw_struct

      # {{{ tks_affected
      @impl true
      def tks_affected() do
        @raw_struct.where
        |> Enum.map(&(Enum.at(&1, 1)))
        |> Enum.uniq()
      end
      # }}}

      # {{{ finds
      @impl true
      def finds() do
        find =  @raw_struct.find
        Enum.reduce(find, %{}, fn 
          {str, :*}, acc -> Map.put(acc, String.to_atom(str), :*)
          {str, li}, acc ->
            lvarkey = String.to_existing_atom(str)
            clause_attrs = Enum.filter(__MODULE__.clauses(), fn %{lvar: lvar} -> lvar == lvarkey end)
                           |> Enum.map(&(&1.attr))

            li = clause_attrs ++ [:id | li] 
                 |> Enum.uniq()

            Map.put(acc, lvarkey, li)
        end)
      end
      # }}}

      # {{{ clauses
      def clauses() do
        for clause <- @raw_struct.where do
          Sorcery.Query.WhereClause.new(clause)
        end
        |> List.flatten()
      end

      @impl true
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
      # }}}

    end
  end # END OF USE


end
