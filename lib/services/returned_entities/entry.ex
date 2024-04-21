defmodule Sorcery.ReturnedEntities do
  @moduledoc """
  This is the return type of any forward query, and any generated data.

  Try not to access the data directly, but rather use the functions in this module.

  The reason is that Sorcery is still a work in progress, the format might change, but the functions should never break their contract.

  This is also the basic format of portals.
  """
  use Norm
  import Sorcery.Helpers.Maps
  import Sorcery.Specs

  defstruct [
    primary_entities: [], # i.e. player: 1, post: 24
    lvar_tks: %{},
    data: %{}
  ]

  defp re_key?(), do: one_of([tk?(), string?()])
   
  # {{{ new() :: struct?(__MODULE__)
  @contract new() :: struct?(__MODULE__)
  @doc ~S"""
  Creates a new, empty RE struct.

  ## Examples
      iex> new()
      %Sorcery.ReturnedEntities{ primary_entities: [], data: %{} }
  """
  def new() do
    struct(__MODULE__, %{})
  end
  # }}}


  # {{{ put_entities(re, tk, li) :: struct?(__MODULE__)
  @contract put_entities(re :: re?(), tk :: re_key?(), li :: list?()) :: re?()
  @doc ~S"""

  ## Examples
      iex> re = Sorcery.ReturnedEntities.new()
      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> re.data.player
      %{1 => %{id: 1, name: "A"}, 23 => %{id: 23, name: "B"}}
      iex> re = put_entities(re, :player, [ %{id: 1, name: "C"}, %{id: 42, name: "B"}])
      iex> re.data.player
      %{1 => %{id: 1, name: "C"}, 23 => %{id: 23, name: "B"}, 42 => %{id: 42, name: "B"}}
  """
  def put_entities(re, tk, li) do
    m = Enum.reduce(li, %{}, fn 
      strct, acc when is_struct(strct) ->
        entity = Map.from_struct(strct) |> Map.delete(:__meta__)
        Map.put(acc, entity.id, entity)

      entity, acc -> 
        Map.put(acc, entity.id, entity)
    end)
    update_in_p(re, [:data, tk], m, &(Map.merge(&1, m)))
  end
  # }}}


  # {{{ delete_entities(re, tk, li) :: re?()
  @contract delete_entities(re?(), re_key?(), list?()) :: re?()
  @doc ~S"""

  Removes all the listed ids of a given tk.

  ## Examples
      iex> re = Sorcery.ReturnedEntities.new()
      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> re.data.player
      %{1 => %{id: 1, name: "A"}, 23 => %{id: 23, name: "B"}}
      iex> re = delete_entities(re, :player, [ 23 ])
      iex> re.data.player
      %{1 => %{id: 1, name: "A"}}
  """
  def delete_entities(re, tk, li) do
    update_in_p(re, [:data, tk], re.data[tk], fn table ->
      Enum.reduce(li, table, fn id, acc ->
        Map.delete(acc, id)
      end)
    end)
  end
  # }}}


  # {{{ delete_attrs(re, tk, li) :: re?()
  @contract delete_attrs(re?(), re_key?(), list?()) :: re?()
  @doc ~S"""

  Deletes attribute keys from every entity of the given tk

  ## Examples
      iex> re = Sorcery.ReturnedEntities.new()
      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> re.data.player
      %{1 => %{id: 1, name: "A"}, 23 => %{id: 23, name: "B"}}
      iex> re = delete_attrs(re, :player, [ :name ])
      iex> re.data.player
      %{1 => %{id: 1}, 23 => %{id: 23}}
  """
  def delete_attrs(re, tk, li) do
    update_in_p(re, [:data, tk], re.data[tk], fn table ->
      Enum.reduce(table, table, fn {id, entity}, acc ->
        entity = Map.reject(entity, fn {k, _} -> k in li end)
        Map.put(acc, id, entity)
      end)
    end)
  end
  # }}}


  # {{{ get_entities(re, tk) :: list
  @contract get_entities(re?(), re_key?()) :: list?()
  @doc ~S"""

  ## Examples
      iex> re = Sorcery.ReturnedEntities.new()
      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> get_entities(re, :player)
      [ %{id: 1, name: "A"}, %{id: 23, name: "B"} ]
  """
  def get_entities(re, tk) do
    re.data[tk]
    |> Map.values()
  end
  # }}}


#  # {{{ get_primary(re, tk) :: map()
#  @contract get_primary(re?(), re_key?()) :: map?()
#  @doc ~S"""
#
#  ## Examples
#      iex> re = Sorcery.ReturnedEntities.new()
#      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"} ])
#      iex> re = put_primary(re, :player, 23)
#      iex> get_primary(re, :player)
#      %{id: 23, name: "B"}
#  """
#  def get_primary(re, tk) do
#    case Keyword.get(re.primary_entities, tk) do
#      nil -> nil
#      id -> re.data[tk][id]
#    end
#  end
#  # }}}
#


#  # {{{ put_primary(re, tk, id) :: re()
#  @contract put_primary(re?(), re_key?(), id?()) :: re?()
#  @doc ~S"""
#
#  ## Examples
#      iex> re = Sorcery.ReturnedEntities.new()
#      iex> re = put_entities(re, :player, [ %{id: 1, name: "A"}, %{id: 23, name: "B"} ])
#      iex> re = put_primary(re, :player, 23)
#      iex> get_primary(re, :player)
#      %{id: 23, name: "B"}
#  """
#  def put_primary(%{primary_entities: pe} = re, tk, id) do
#    pe = Keyword.put(pe, tk, id)
#    Map.put(re, :primary_entities, pe)
#  end
#  # }}}


  def assign_lvar_tk(re, lvar, tk), do: put_in_p(re, [:lvar_tks, lvar], tk)


  # {{{ apply_find_map(re, find) :: re
  @doc """
  Prunes all the entities by applying Map.take(li) to each.
  ## Examples
      iex> re = Sorcery.ReturnedEntities.new()
      iex> re = put_entities(re, :bird, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> re = put_entities(re, :spell, [ %{id: 1, name: "A"}, %{id: 23, name: "B"}])
      iex> get_entities(re, :bird)
      [ %{id: 1, name: "A"}, %{id: 23, name: "B"} ]
      iex> re = apply_find_map(re, %{bird: [:id]})
      iex> get_entities(re, :bird)
      [ %{id: 1}, %{id: 23} ]
  """
  def apply_find_map(re, find) do
    find = convert_find_type(re, find)
    re = Enum.reduce(find, re, fn {tk, attrs}, re ->
      table = 
        re.data[tk]
        |> Enum.reduce(%{}, fn {id, entity}, acc ->
          entity = Map.take(entity, attrs)
          Map.put(acc, id, entity)
        end)
      put_in_p(re, [:data, tk], table)
    end)

    keys_in_re = Map.keys(re.data) |> MapSet.new()
    keys_in_find = Map.keys(find)  |> MapSet.new()
    difference = MapSet.difference(keys_in_re, keys_in_find)
    Enum.reduce(difference, re, fn k, re -> delete_in(re, [:data, k]) end)
  end
  defp convert_find_type(re, find) do
    re_atom? = re.data |> Map.keys() |> List.first() |> is_atom()
    find_atom? = find |> Map.keys() |> List.first() |> is_atom()
    case {re_atom?, find_atom?} do
      {false, false} -> find
      {true,  true} -> find
      {true,  false} -> to_atom_keys(find)
      {false,  true} -> to_string_keys(find)
    end
  end
  # }}}


end
