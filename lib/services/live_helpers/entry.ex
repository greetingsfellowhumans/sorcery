defmodule Sorcery.LiveHelpers do
  @moduledoc ~s"""
  Functions for combining Sorcery and LiveViews
  """

  # {{{ callback docs
  @doc ~s"""
  Creates a portal between the LiveView and the PortalServer, using the given arguments.

  Takes the socket, returns it unchanged.

  ## Examples
      iex> body = %{portal_server: Postgres, portal_name: :my_portal, query_module: MyQuery, query_args: %{player_id: 1}}
      iex> socket = spawn_portal(socket, body)
  """
  @type socket_type :: %{optional(any) => any, :__struct__ => Phoenix.LiveView.Socket, :assigns => map()} #%{__struct__: Phoenix.LiveView.Socket, assigns: map(), optional(any) => any}

  @callback spawn_portal(socket :: socket_type, body :: %{
    portal_server: module(),
    portal_name: atom(),
    query_module: module(),
    query_args: map(),
  }) :: socket_type


  @doc ~s"""
  Puts a :sorcery key in socket.assigns, with a bunch of stuff used behind the scenes by Sorcery.

  This is mandatory, before you can spawn any portals

  You must pass in the sorcery_module. If you used the generator, it'll just be Src.

  ## Examples
      iex> body = %{sorcery_module: Src}
      iex> socket = initialize_sorcery(socket, body)
  """
  @callback initialize_sorcery(socket :: socket_type, body :: %{
    optional(:sorcery_module) => module(),
    optional(:args) => map(),
    optional(:store_adapter) => module()
  }) :: socket_type


  @doc ~s"""
  Get a list of entities at the given portal/lvar
  You probably want to use this inside heex
  ```elixir
  <% players = portal_view(@sorcery, :my_portal, "?all_players") %>
  ```
  """
  @callback portal_view(sorcery_config :: map(), portal_name :: atom(), lvar :: binary()) :: list()


  @doc ~s"""
  Get a list of entities at the given lvar. 

  If this lvar only exists in ONE portal, you can leave out the portal_name, just know that it might be imperceptibly slower since the function needs to iterate over all portals until it finds one with that lvar..

  ```elixir
  <% players = portal_view(@sorcery, "?all_players") %>
  ```
  """
  @callback portal_view(sorcery_config :: map(), lvar :: binary()) :: list()

  #@doc """
  #When a PortalServer needs to send a message to this LiveView, it goes through this.

  #You can still use your own `handle_info` functions with different function heads. But `handle_info({:sorcery, _}, socket)` is reserved.
  #"""


  # }}}

  defmacro __using__(_) do
    quote do
      @behaviour Sorcery.LiveHelpers

      # {{{ spawn_portal/2
      @impl true
      def spawn_portal(socket, %{portal_server: parent, portal_name: name, query_module: mod, query_args: args} = body) do
          if connected?(socket) do
          msg = %{
            command: :create_portal,
            portal_name: name,
            #query_module: Module.concat(socket.assigns.sorcery.config_module, mod),
            query_module: mod,
            child_pid: self(),
            args: args,
          }
          send(Module.concat([socket.assigns.sorcery.config_module, "PortalServers", parent]), {:sorcery, msg})
        end

        socket
      end
      @impl true
      def spawn_portal(_, body) do
        expected = [:portal_server, :portal_name, :query_module, :query_args]
        expected_str = Enum.reduce(expected, "", fn k, acc -> ":#{k} " <> acc end)

        actual = Map.keys(body)
        actual_str = Enum.reduce(actual, "", fn k, acc -> ":#{k} " <> acc end)

        missing = MapSet.difference(MapSet.new(expected), MapSet.new(actual)) |> MapSet.to_list()
        missing_str = Enum.reduce(missing, "", fn k, acc -> ":#{k} " <> acc end)

        raise ~s"""
        You called spawn_portal/2 in #{__MODULE__}, which is a good start, but you're missing some data.

        The second argument of spawn_portal requires the following keys
        #{expected_str}

        But you passed in
        #{actual_str}

        Which is missing
        #{missing_str}

        """

      end
      # }}}


      # {{{ initialize_sorcery/2
      @impl true
      def initialize_sorcery(socket, body \\ %{}) do
        mod = Map.get(body, :sorcery_module, Src)
        assigns = Sorcery.PortalServer.add_portal_server_state(socket.assigns, %{
          config_module: mod,
          store_adapter: Map.get(body, :store_adapter, Sorcery.StoreAdapter.InMemory),
          args: Map.get(body, :args, %{})
        })
        socket = assign(socket, :sorcery, assigns.sorcery)

        socket
      end
      # }}}


    # {{{ handle_sorcery({:sorcery, msg}, socket)
    def handle_sorcery({:sorcery, msg}, socket) do
      inner_state = Sorcery.PortalServer.handle_info(msg, socket.assigns.sorcery)
      {:noreply, assign(socket, :sorcery, inner_state)}
    end
    # }}}


    # {{{ portal_view(sorcery, portal_name, lvar)
    @impl true
    def portal_view(sorcery, lvar) do
      portal_name = Enum.find_value(sorcery.portals, fn {name, portal} ->
        lvars = Map.keys(portal.known_matches.lvar_tks)
        if lvar in lvars do
          name
        else
          nil
        end
      end)
      portal_view(sorcery, portal_name, lvar)
    end
    @impl true
    def portal_view(sorcery, portal_name, lvar) do
      Sorcery.PortalServer.Portal.get_in(sorcery, portal_name, lvar)
    end
    # }}}



      
    end
  end



end
