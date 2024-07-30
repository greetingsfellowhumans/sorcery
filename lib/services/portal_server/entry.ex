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
  use Sorcery.PortalServer

  def init(_) do
    state = %{} # You can still add whatever you want here

    state = Sorcery.PortalServer.add_portal_server_state(state, %{
      config_module: Src,
      store_adapter: Sorcery.StoreAdapters.Ecto,

      # This depends on the adapters you use
      args: %{
        repo_module: MyApp.Repo
      }
    })

    {:ok, state}
  end
  ```
  """


  def add_portal_server_state(outer_state, opts) do
    inner_state = Sorcery.PortalServer.InnerState.new(opts)
    Map.put(outer_state, :sorcery, inner_state)
  end
   
  defmacro __using__(_) do
    quote do
      #@impl Sorcery.PortalServer
      #def handle_info({:sorcery, msg}, state) do
      #  new_state = Sorcery.PortalServer.handle_info(msg, state)
      #  {:noreply, new_state}
      #end
    end
  end

  @doc false
  def handle_info(%{command: :create_portal} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.CreatePortal.entry(msg, state)
  def handle_info(%{command: :portal_merge} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.PortalMerge.entry(msg, state)
  def handle_info(%{command: :run_mutation} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.RunMutation.entry(msg, state)
  def handle_info(%{command: :portal_put} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.PortalPut.entry(msg, state)
  def handle_info(%{command: :mutation_failed} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.MutationFailed.entry(msg, state)
  def handle_info(%{command: :mutation_success} = msg, %Sorcery.PortalServer.InnerState{} = state), do: Cmd.MutationSuccess.entry(msg, state)

  def handle_info(%{command: cmd}, %Sorcery.PortalServer.InnerState{}) do
    raise "#{cmd} was just sent as a :command."
  end
  def handle_info(msg, %{sorcery: inner_state}), do: handle_info(msg, inner_state)


end
