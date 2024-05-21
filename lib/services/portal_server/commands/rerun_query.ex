defmodule Sorcery.PortalServer.Commands.RerunQuery do
  @moduledoc false
  import Sorcery.Helpers.Maps


  def entry(%{portal_name: portal_name} = msg, state) do
    dbg msg
    parent_pid = Enum.find_value(state.sorcery.portals_to_parent, fn {pid, name} ->
      if name == portal_name, do: pid, else: nil
    end)

    mod = get_in(state, [:sorcery, :portals_to_parent, parent_pid, portal_name, :query_module])
    msg = %{
      command: :run_query,
      query: mod,
      from: self()
    }
    send(parent_pid, {:sorcery, msg})
    state
  end

end

