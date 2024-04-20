defmodule Sorcery.Query.ResultsLog do
  @moduledoc ~s"""
  One challenge with reverse queries is when a clause's right value is actually an lvar.
  For example
  `["?player", :player, :team_id, "?team.id"]`

  Because during a reverse query, we receive a diff, and must ask the Sorcery Query: "Is this diff relevant to you?"
  And in order to answer that, it needs to know the :id of every ?team. So we hold a dataframe tracking those ids, adding to them when a new team comes in.

  Every time a forward query is run by a Portal Server, it records the results in a ResultsLog for the sake of future ReverseQueries.
  First we scan the SorceryQuery and gather all the lvar/attr pairs,
  Second, we create a dataframe
  """
  #alias Explorer.DataFrame, as: DF
  alias Sorcery.ReturnedEntities, as: RE

  def scan_for_pairs(clauses) do
    Enum.map(clauses, &(Sorcery.Query.ResultLogPair.new(clauses, &1)))
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.uniq()
  end

  def pairs_to_df(pairs, returned_entities) do
    Enum.map(pairs, &(pair_to_df(&1, returned_entities)))
  end
  def pair_to_df(pair, returned_entities) do
    entities = RE.get_entities(returned_entities, "#{pair.lvar}")
    set = Enum.reduce(entities, MapSet.new([]), fn entity, set ->
      v = Map.get(entity, pair.attr)
      MapSet.put(set, v)
    end)
    Map.put(pair, :value, set)
  end

end
defmodule Sorcery.Query.ResultLogPair do
  defstruct [
    :tk, :attr, :lvar, :value
  ]

  @doc ~s"""
    Returns EITHER a struct, or nil.

  """
  def new(_, %Sorcery.Query.WhereClause{other_lvar: nil}), do: nil
  def new(all_clauses, %Sorcery.Query.WhereClause{other_lvar: lvar, other_lvar_attr: attr}) do
    attr = attr || :id
    tk = Enum.find_value(all_clauses, fn c -> if c.lvar == lvar, do: c.tk, else: nil end)
    struct(__MODULE__, %{attr: attr, lvar: lvar, tk: tk})
  end

end
