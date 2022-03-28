defmodule Sorcery.Storage.GenserverAdapter.Unmount do
  @moduledoc false

  alias Sorcery.Utils.Maps


  def unmount(pid, state) do
    included = get_entities_for_pid(pid, state)
    excluded = get_entities_excluding_pid(pid, state)
    needed_entities = MapSet.difference(excluded, included)
    default_db = Enum.reduce(Map.keys(state.db), %{}, fn k, d -> Map.put(d, k, %{}) end)
    new_db = Enum.reduce(needed_entities, default_db, fn {tk, id}, db ->
      table = Map.get(state.db, tk, %{})
      entity = Map.get(table, id, %{})
      Maps.put_in_p(db, [tk, id], entity)
    end)
    Map.put(state, :db, new_db)
  end


  def get_entities_for_pid(pid, state) do
    portals = 
      Sorcery.Portal.all_portals(state)
      |> Enum.filter(fn %{pid: portal_pid} -> pid == portal_pid end)

    qm = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
    db = Sorcery.Storage.GenserverAdapter.Query.solve_portals(portals, qm)
    Enum.reduce(db, MapSet.new([]), fn {tk, table}, acc ->
      ids = Map.keys(table)
      table_entities = Enum.map(ids, fn id -> {tk, id} end) |> MapSet.new()
      MapSet.union(acc, table_entities)
    end)
  end


  def get_entities_excluding_pid(pid, state) do
    portals = 
      Sorcery.Portal.all_portals(state)
      |> Enum.filter(fn %{pid: portal_pid} -> pid != portal_pid end)

    qm = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
    db = Sorcery.Storage.GenserverAdapter.Query.solve_portals(portals, qm)
    Enum.reduce(db, MapSet.new([]), fn {tk, table}, acc ->
      ids = Map.keys(table)
      table_entities = Enum.map(ids, fn id -> {tk, id} end) |> MapSet.new()
      MapSet.union(acc, table_entities)
    end)
  end


end
