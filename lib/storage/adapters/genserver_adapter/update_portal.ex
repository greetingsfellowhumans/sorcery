defmodule Sorcery.Storage.GenserverAdapter.UpdatePortal do
  @moduledoc """
  Pure functions for all portal manipulation.
  """

  use Norm
  #alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
  alias Sorcery.Storage.GenserverAdapter.ViewPortal


  @contract add_ids(PT.portal(), AdapterT.client_state()) :: PT.portal() 
  @doc """
  Takes a portal, returns a portal with an updates :ids.
  """
  def add_ids(portal, state) do
    ids = ViewPortal.get_portal_ids(portal, state)
    Map.put(portal, :ids, ids)
  end


  @contract add_indices(PT.portal(), AdapterT.client_state()) :: PT.portal() 
  @doc """
  Takes a portal, returns a portal with the indexed values filled in.
  """
  def add_indices(portal, state) do
    entities = ViewPortal.view_portal(portal, state)
    indices = Enum.reduce(portal.indices, %{}, fn {k, _}, acc ->
      v = Enum.map(entities, fn {_, e} -> Map.get(e, k) end) |> MapSet.new()
      Map.put(acc, k, v)
    end)
    Map.put(portal, :indices, indices)
  end


end
