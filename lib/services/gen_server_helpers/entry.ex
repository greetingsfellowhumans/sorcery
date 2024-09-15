defmodule Sorcery.GenServerHelpers do
  @moduledoc ~s"""
  Functions for combining Sorcery and GenServer clients.
  Put these in your init function to create portals and receive updates.
  """

  # {{{ callback docs
  @doc ~s"""
  Creates a portal between the GenServer and the PortalServer, using the given arguments.

  Takes the state, returns it unchanged. An update should happen in a few milliseconds to add more data to the state..

  ## Examples
      iex> body = %{portal_server: Postgres, portal_name: :my_portal, query_module: MyQuery, query_args: %{player_id: 1}}
      iex> state = spawn_portal(state, body)
  """
  @callback spawn_portal(state :: map(), body :: %{
    portal_server: module(),
    portal_name: atom(),
    query_module: module(),
    query_args: map(),
  }) :: map()


  @doc ~s"""
  Puts a :sorcery key in state, with a bunch of stuff used behind the scenes by Sorcery.

  This is mandatory, before you can spawn any portals

  You must pass in the sorcery_module. If you used the generator, it'll just be Src.

  ## Examples
      iex> body = %{sorcery_module: Src}
      iex> state = initialize_sorcery(state, body)
  """
  @callback initialize_sorcery(state :: map(), body :: %{
    optional(:sorcery_module) => module(),
    optional(:args) => map(),
    optional(:store_adapter) => module()
  }) :: map()


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


  # }}}

  defmacro __using__(_) do
    quote do
      @behaviour Sorcery.GenServerHelpers


      # {{{ spawn_portal/2
      @impl true
      def spawn_portal(%Sorcery.PortalServer.InnerState{} = inner_state, %{portal_server: parent, portal_name: name, query_module: mod, query_args: args} = body) do
        msg = %{
          command: :create_portal,
          portal_name: name,
          query_module: mod,
          child_pid: self(),
          args: args,
        }
        send(Module.concat([inner_state.config_module, "PortalServers", parent]), {:sorcery, msg})

        inner_state
      end
      @impl true
      def spawn_portal(inner_state, body) do
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
      def initialize_sorcery(state, body \\ %{}) do
        mod = Map.get(body, :sorcery_module, Src)
        Sorcery.PortalServer.add_portal_server_state(state, %{
          config_module: mod,
          store_adapter: Map.get(body, :store_adapter, Sorcery.StoreAdapter.InMemory),
          args: Map.get(body, :args, %{})
        })
      end
      # }}}


    # {{{ handle_sorcery({:sorcery, msg}, state)
    def handle_sorcery({:sorcery, msg}, state) do
      inner_state = Sorcery.PortalServer.handle_info(msg, state.sorcery)
      {:noreply, Map.put(state, :sorcery, inner_state)}
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

