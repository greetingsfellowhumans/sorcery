defmodule Sorcery.LiveHelpers do
  @moduledoc false


  defmacro __using__(_) do
    quote do

      # {{{ spawn_portal/2
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
      def initialize_sorcery(socket, %{sorcery_module: mod} = body) do
        assigns = Sorcery.PortalServer.add_portal_server_state(socket.assigns, %{
          config_module: mod,
          store_adapter: Map.get(body, :store_adapter, Sorcery.StoreAdapter.InMemory),
          args: Map.get(body, :args, %{})
        })
        socket = assign(socket, :sorcery, assigns.sorcery)

        socket
      end
      # }}}


    # {{{ handle_info({:sorcery, msg})
    def handle_info({:sorcery, msg}, socket) do
      resp = Sorcery.PortalServer.handle_info(msg, socket.assigns)
      {:noreply, assign(socket, :sorcery, resp.sorcery)}
    end
    # }}}


    # {{{ portal_view(sorcery, portal_name, lvar)
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
    def portal_view(sorcery, portal_name, lvar) do
      Sorcery.PortalServer.Portal.get_in(sorcery, portal_name, lvar)
    end
    # }}}



      
    end
  end



end
