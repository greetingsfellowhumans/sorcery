defmodule Sorcery.Specs do
  #defmacro __using__(_) do
  #  quote do
  use Norm

  #############################
  # Primatives
  #############################
  def bool?(), do: spec(is_boolean())
  def string?(), do: spec(is_binary())
  def atom?(), do: spec(is_atom())
  def int?(), do: spec(is_integer())
  def id?(), do: spec(is_integer() and fn id -> id > 0 end)
  def float?(), do: spec(is_float())
  def number?(), do: spec(is_float() or is_integer())
  def list?(), do: spec(is_list())
  def map?(), do: spec(is_map())
  def mapset?(), do: spec(is_struct(MapSet))
  def nil?(), do: spec(is_nil())
  def any?(), do: spec(fn _ -> true end)
  def kwli?(), do: coll_of({atom?(), any?()})
  def mod?(), do: atom?()
  def struct?(), do: spec(is_struct())
  def struct?(t), do: spec(is_struct(t))
  def function?(), do: spec(is_function())
  def naive_datetime(), do: spec(is_struct(NaiveDateTime))
  def pid?(), do: spec(is_pid())
  def tuple?(), do: spec(is_tuple())
  def ref?(), do: spec(is_reference())


  #############################
  # Sorceryisms
  #############################
  def re?(), do: struct?(Sorcery.ReturnedEntities)
  def tk?(), do: atom?()
      
  #  end
  #end


end

defmodule Sorcery.Specs.Imports do
#    import Norm
#
#    #############################
#    # Primatives
#    #############################
#    def bool?(), do: spec(is_boolean())
#    def string?(), do: spec(is_binary())
#    def atom?(), do: spec(is_atom())
#    def int?(), do: spec(is_integer())
#    def id?(), do: spec(is_integer() and fn id -> id > 0 end)
#    def float?(), do: spec(is_float())
#    def number?(), do: spec(is_float() or is_integer())
#    def list?(), do: spec(is_list())
#    def map?(), do: spec(is_map())
#    def mapset?(), do: spec(is_struct(MapSet))
#    def nil?(), do: spec(is_nil())
#    def any?(), do: spec(fn _ -> true end)
#    def kwli?(), do: coll_of({atom?(), any?()})
#    def mod?(), do: atom?()
#    def struct?(), do: spec(is_struct())
#    def struct?(t), do: spec(is_struct(t))
#    def function?(), do: spec(is_function())
#    def naive_datetime(), do: spec(is_struct(NaiveDateTime))
#    def pid?(), do: spec(is_pid())
#    def tuple?(), do: spec(is_tuple())
#    def ref?(), do: spec(is_reference())
#
#
#    #############################
#    # Structs
#    #############################
#    #def query?(), do: struct?(P.Query)
#    #def query_log?(), do: struct?(P.QueryLog)
#    #def query_log_row?(), do: struct?(P.QueryLogRow)
#    #def query_log_match?(), do: struct?(P.QueryLog.Match)
#    #def diff?(), do: struct?(P.Diff)
#    #def definition?(), do: struct?(P.Definition)
#    #def where_clause?(), do: struct?(P.WhereClause)
#    #def store_config?(), do: struct?(P.StoreConfig)
#    #def live_view_config?(), do: struct?(P.LiveViewAdapter.AssignConfig)
#    #def ticket?(), do: struct?(P.Ticket)
#
#
#
#    #############################
#    # Datalog
#    # {did, tk, attr, value}
#    #
#    # Such that:
#    # The did is always of type lid
#    # the tk is always of type atom
#    # the attr is always of type atom
#    # the value changes type depending on the attr.
#    #############################
#
#    @doc """
#    Logic Id. uniquely identifies an lvar within scope. Starts with a $
#    A lid represents a set of ids for the given tk
#    """
#    #def lid?(), do: spec(is_binary() and fn
#    #  "$" <> _ -> true
#    #  _ -> false
#    #end)
#
#    #def op?(), do: one_of([:==, :!=, :>, :>=, :<, :<=, :in, :lid])
#
#    ## Columns
#    ## Definition id. is the first elem of the tuple. always.
#    #def did?(), do: lid?()
#
#    ## table key is a snakecase atom like :dog_pack
#    #def tk?(), do: atom?()
#
#    ## a key column within that table. e.g. :name or :weeks_old
#    #def attr?(), do: atom?()
#    #def value?(), do: any?()
#    #def before_value?(), do: any?()
#    #def after_value?(), do: any?()
#    #
#    #def where_clauses?(), do: coll_of(where_clause?())
#    #def diff_clause?(), do:  {attr?(), before_value?(), after_value?()}
#    #def diffs?(), do: coll_of(diff?())
#    ##def portals?(), do: map_of(lid?(), definition?())
#    #def portal?(), do: map_of(lid?(), definition?())
#
#
#    ## e.g. %Dog{id: 1, name...} or %{id: 1, name...}
#    #def entity?(), do: schema(%{id: id?()})
#
#    #def sorcery_query?(), do: struct?(Sorcery.Query) 
#
#
end
