defmodule Sorcery.Storage.GenserverAdapter.GetPresence do
  @moduledoc """
  Pure functions for pulling a list of entities out of a portal.
  """
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT

  #@contract my_portals(AdapterT.client(), T.any(), spec(is_map())) :: coll_of(PT.portal)
  @doc """
  List all portals matching the current pid.
  """
  def my_portals(client, presence, opts) do
    %{tables: tables} = client.get_state(opts)
    tks = Map.keys(tables)
    Enum.reduce(tks, [], fn tk, acc -> 
      case presence.list("portals:#{tk}") do
        nil -> acc
        presences ->
          Enum.reduce(presences, acc, fn {_ref, %{metas: [portal]}}, acc ->
            if portal.pid == self() do
              [portal | acc]
            else
              acc
            end
          end)
      end
    end)
  end


  def get_portal(presence, portal_ref, _opts) do
    [tk, _] = String.split(portal_ref, ":")
    %{metas: [portal]} = presence.get_by_key("portals:#{tk}", portal_ref)
    portal
  end


end


