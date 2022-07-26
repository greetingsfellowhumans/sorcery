defmodule Sorcery.Storage.GenserverAdapter.QueryMeta do
  alias Sorcery.Utils.Maps

  @moduledoc false

  defstruct [
    all_table_keys: MapSet.new(),
    all_entities: MapSet.new(), # Format: MapSet.new([{tk, id}])
    old_db: %{},
    new_db: %{}
  ]

  def new(state) do
    %__MODULE__{new_db: state.db}
  end
  def new(src, state) do
    qm = %__MODULE__{}
    Enum.reduce(src.changes_db, qm, fn {tk, table}, acc ->
      acc = Enum.reduce(table, acc, fn {id, partial_entity}, acc ->
        entity = Map.get(state.db[tk], id, %{})
        new_entity = Map.merge(entity, partial_entity)
        acc
        |> Map.update!(:all_entities, fn set -> MapSet.put(set, {tk, id}) end)
        |> Maps.put_in_p([:old_db, tk, id], entity)
        |> Maps.put_in_p([:new_db, tk, id], new_entity)
      end)

      all_table_keys = MapSet.put(acc.all_table_keys, tk)
      Map.put(acc, :all_table_keys, all_table_keys)
    end)
  end

end


defmodule Sorcery.Storage.GenserverAdapter.Query do
  use Norm
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
  alias Sorcery.Utils.Maps


  @contract solve_portal(PT.portal(), AdapterT.qmeta()) :: T.db()
  @doc """
  Given a portal, return a db of entities satisfying it.
  """
  def solve_portal(portal, qmeta) do
    tk = Map.get(portal, :tk)
    #old = Map.get(qmeta.old_db, tk, %{})
    new = Map.get(qmeta.new_db, tk, %{})
    table = new #Map.merge(old, new)
            |> Enum.reduce(%{}, fn {id, entity}, acc ->
              if portal_watching_entity?(portal, entity) do
                Map.put(acc, id, entity)
              else
                acc
              end
            end)

    if Enum.empty?(table) do
      %{tk => %{}}
    else
      %{tk => table}
    end
  end



  @contract solve_portals(coll_of(PT.portal()), AdapterT.qmeta()) :: T.db()
  @doc """
  Given a list of portals, return a db of entities satisfying it.
  """
  def solve_portals(portals, qmeta) do
    Enum.reduce(portals, %{}, fn portal, acc -> 
      Maps.deep_merge(acc, solve_portal(portal, qmeta))
    end)
  end


  @contract affects_portal?(PT.portal(), AdapterT.qmeta()) :: T.bool
  @doc """
  Determine if a portal is observing any of the entities in the qmeta
  """
  def affects_portal?(portal, qmeta) do
    tk = Map.get(portal, :tk)
    old = Map.get(qmeta.old_db, tk, %{})
    new = Map.get(qmeta.new_db, tk, %{})
    db = Map.merge(old, new)
    Enum.any?(db, fn {_, entity} ->
      portal_watching_entity?(portal, entity)
    end)
  end
  

  @contract affects_portals?(coll_of(PT.portal()), AdapterT.qmeta()) :: T.bool
  def affects_portals?(portals, qmeta) do
    Enum.any?(portals, fn portal ->
      affects_portal?(portal, qmeta)
    end)
  end


  @contract affected_pids(coll_of(PT.portal()), AdapterT.qmeta()) :: coll_of(T.pid())
  @doc """
  Given a list of ALL connected portals, return a list of pids, such that at least one of their portals is affected by the qmeta.
  Careful, we're potentially working with huge amounts of data.
  """
  def affected_pids(all_portals, qmeta) do
    Enum.group_by(all_portals, fn %{pid: pid} -> pid end)
    |> Enum.reduce([], fn {pid, portals}, acc ->
      if affects_portals?(portals, qmeta) do
        [pid | acc]
      else
        acc
      end
    end)
  end


  def entity_matches_clause?(entity, {:or, guards}) do
    Enum.any?(guards, fn guard -> entity_matches_clause?(entity, guard) end)
  end
  def entity_matches_clause?(entity, {:and, guards}) do
    Enum.all?(guards, fn guard -> entity_matches_clause?(entity, guard) end)
  end
  def entity_matches_clause?(entity, {:in, attr, set}) do
    Map.get(entity, attr) in set
  end
  def entity_matches_clause?(entity, {fun, attr, v}) do
    cb = Function.capture(Kernel, fun, 2)
    e = Map.get(entity, attr)
    cb.(e, v)
  end

  def portal_watching_entity?(portal, entity) do
    Enum.all?(portal.resolved_guards, fn guard -> entity_matches_clause?(entity, guard) end)
  end


  @doc """
  Given a list of portals, recalculate such that:
    1. Every tuple of {ref, attr} in a guard will become a MapSet of values in the resolve_guard.
    2. Every entity matching the portal will be found, and indexed
  """
  def resolve_portal(portals, state) do
    Enum.map(portals, fn %{guards: guards} = portal ->
      resolved_guards = Enum.map(guards, fn
        {:in, attr, {ref, ref_attr}} ->
          reffed_portal = Enum.find(portals, fn p -> p.id == ref end)
          index = Map.get(reffed_portal.indices, ref_attr)
          {:in, attr, index}

        guard -> guard
      end)

      portal
      |> Map.put(:resolved_guards, resolved_guards)
      |> build_indices(state)

    end)
  end


  defp build_indices(%{tk: tk} = portal, state) do
    # Get all entities matching
    entities = Enum.reduce(state.db[tk], [], fn {_id, entity}, acc ->
      if portal_watching_entity?(portal, entity) do
        [entity | acc]
      else
        acc
      end
    end)

    indices = Enum.reduce(portal.indices, %{}, fn {attr, _}, acc ->
      index = Enum.map(entities, fn e -> Map.get(e, attr) end) |> MapSet.new()
      Map.put(acc, attr, index)
    end)

    Map.put(portal, :indices, indices)
  end


end
