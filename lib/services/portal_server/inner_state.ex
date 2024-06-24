defmodule Sorcery.PortalServer.InnerState do
  @moduledoc """
  This exists to resolve a lot of confusion caused by generically using the word 'state' to refer to either the data inside the :sorcery key, or the data *including* :sorcery.
  For example a LiveView would have socket.assigns.sorcery
  So does state refer to socket.assigns? Or socket.assigns.sorcery?
  In theory, Sorcery should never need to access the outer map, aside from maybe the helpers at most.

  So to save confusion, InnerState is ONLY ever the value of the :sorcery key.
  There is no OuterState struct, as it depends on how the user configures the PortalServer.
  """
  defstruct [
    config_module: Module.concat(["Src"]),
    store_adapter: Sorcery.StoreAdapter.InMemory,
    pending_portals: [],
    args: %{},
    portals: %{},
  ]

  def new(body), do: struct(__MODULE__, body)
end
