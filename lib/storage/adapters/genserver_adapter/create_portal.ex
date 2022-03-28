defmodule Sorcery.Storage.GenserverAdapter.CreatePortal do
  @moduledoc false
  use Norm
  alias Sorcery.Storage.GenserverAdapter.ViewPortal


  def create_portal_map(attrs, pid) do
    attrs
    |> Map.put(:pid, pid)
    |> Sorcery.Portal.new()
    |> Map.from_struct()
  end


  @doc """
  This operation iterates over every presence, and does 2 things:
    1. solves the resolved guards
    2. Solves the indices
  """
  def parse_portal(portal, state) do
    portal
    |> resolve_guards(state)
    |> solve_indexes(state)
  end


  defp resolve_guard({:or, guards}, state) do
    values = Enum.map(guards, fn g -> resolve_guard(g, state) end)
    {:or, values}
  end
  defp resolve_guard({:in, attr, {ref, ref_attr}}, state) do
    ref_values = ViewPortal.view_portal(ref, state)
                |> Enum.map(fn {_, e} -> Map.get(e, ref_attr) end)
                |> MapSet.new()
    {:in, attr, ref_values}
  end
  defp resolve_guard(guard, _state), do: guard
  defp resolve_guards(portal, state) do
    resolved_guards = Enum.map(portal.guards, fn guard -> resolve_guard(guard, state) end)
    Map.put(portal, :resolved_guards, resolved_guards)
  end

  defp solve_indexes(portal, state) do
    entities = ViewPortal.view_portal(portal, state)
    Enum.reduce(portal.indices, portal, fn {attr, _}, acc ->
      index = rebuild_index(attr, entities)
      put_in(acc, [:indices, attr], index)
    end)
  end

  defp rebuild_index(attr, entities) do
    Enum.map(entities, fn {_id, entity} -> Map.get(entity, attr) end)
    |> MapSet.new()
  end

end
