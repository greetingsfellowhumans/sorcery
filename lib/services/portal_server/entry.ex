defmodule Sorcery.PortalServer do
  @moduledoc """
  A PortalServer is a special type of GenServer. Portals are created between different PortalServers, always in a hierarchical parent <--> child relationship.

  Every PortalServer must have access to some kind of data store. That might be Postgres via Ecto.Repo... or it could be a LiveView storing data in socket.assigns. (Remember, LiveViews *are* GenServers!)
  You can even create your own adapter and use ANY backend as the data store, as long as you can query and mutate the data.

  ## Setup
  A PortalServer is any GenServer that holds a special :sorcery key somewhere in its state, and also handles messages sent to {:sorcery, msg}
  """
  alias Sorcery.PortalServer.Commands, as: Cmd

  @doc """
  To convert any process into a PortalServer, you must follow 2 steps:
  1) Add some PortalServer configuration to the state
  2) Implement the PortalServer handlers for a handle_info function


  ```elixir
  use GenServer

  def init(_) do
    state = %{} # You can still add whatever you want here

    state = Sorcery.PortalServer.add_portal_server_state(state, %{
      config_module: MyApp.Sorcery,      # This is a required key

      db: %{}, # In memory storage of entities being tracked by portals

      store_adapter: Sorcery.StoreAdapters.Ecto,

      # This depends on the adapters you use
      args: %{
        repo_module: MyApp.Repo
      }
    })

    {:ok, state}
  end

  def handle_info({:sorcery, msg}, state) do
    new_state = Sorcery.PortalServer.handle_info(msg, state)
    {:noreply, new_state}
  end
  ```
  """


  def add_portal_server_state(state, %{config_module: _mod} = opts) do
    state
    |> Map.put(:sorcery, opts)
    |> put_in([:sorcery, :portals], %{})
  end
   

  def handle_info(%{command: :create_portal} = msg, state), do: Cmd.CreatePortal.entry(msg, state)
  def handle_info(%{command: :portal_merge} = msg, state), do: Cmd.PortalMerge.entry(msg, state)
  def handle_info(%{command: :run_mutation} = msg, state), do: Cmd.RunMutation.entry(msg, state)
  def handle_info(%{command: :portal_put} = msg, state), do: Cmd.PortalPut.entry(msg, state)

  def handle_info(%{command: cmd} = msg, state) do
    raise "#{cmd} was just sent as a :command."
  end


end
