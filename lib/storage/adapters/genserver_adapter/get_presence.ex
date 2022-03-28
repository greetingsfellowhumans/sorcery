defmodule Sorcery.Storage.GenserverAdapter.GetPresence do
  @moduledoc false

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


