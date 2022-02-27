defmodule Sorcery.Storage.GenserverAdapter.ViewPortal do
  @moduledoc """
  Pure functions for pulling a list of entities out of a portal.
  """
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT



  #@contract view_portal(PT.portal(), AdapterT.client_state()) :: T.tablemap() 
  @doc """
  Given a portal, and the state, return a map of all the entities which satisfy all guards.
  """
  def view_portal(%{tk: tk, resolved_guards: guards} = _portal, state) do
    table = Map.get(state.db, tk, %{})
    Enum.reduce(table, %{}, fn {id, entity}, acc ->
      if satisfies_all_guards?(entity, guards) do
        Map.put(acc, id, entity)
      else
        acc
      end
    end)
  end
  #@contract view_portal(PT.portal_ref(), AdapterT.client_state()) :: T.tablemap() 
  def view_portal(ref, state) do
    [tk | _] = String.split(ref, ":")
    tk = String.to_existing_atom(tk)
    case state.presence.get_by_key("portals:#{tk}", ref) do
      %{metas: [portal]} -> view_portal(portal, state)
      [] -> %{}
    end
  end


  @contract get_portal_ids(PT.portal(), AdapterT.client_state()) :: coll_of(T.id_int)
  @doc """
  Get a set of ids for the entities found by a given portal.
  """
  def get_portal_ids(portal, state) do
    view_portal(portal, state) |> Map.keys() |> MapSet.new()
  end



  defp satisfies_guard?(entity, {:or, guards}) do
    Enum.any?(guards, fn guard -> satisfies_guard?(entity, guard) end)
  end
  # Otherwise, compiler says Kernel.in/2 is undefined. I don't know why. This is a fix for now.
  defp satisfies_guard?(entity, {:in, attr, guard_value}) do
    ent_val = Map.get(entity, attr)
    Kernel.in(ent_val, guard_value)
  end
  defp satisfies_guard?(entity, {fun_atom, attr, guard_value}) do
    fun = Function.capture(Kernel, fun_atom, 2)
    ent_val = Map.get(entity, attr)
    fun.(ent_val, guard_value)
  end

  defp satisfies_all_guards?(entity, guards) do
    Enum.all?(guards, fn guard -> satisfies_guard?(entity, guard) end)
  end


end

