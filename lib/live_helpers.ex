defmodule Sorcery.LiveHelper do
  defmacro __using__([client: client, presence: presence]) do
    quote do


      def assign_portals(socket) do
        portals = Sorcery.Storage.GenserverAdapter.GetPresence.my_portals(unquote(client), unquote(presence), %{})
        state = unquote(client).get_state(%{})
        assign_portals(socket, portals, state)
      end
      def assign_portals(socket, my_portals, state) do
        qm = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
        portal_meta = []
        portals = %{}

        {portal_meta, portals} = Enum.reduce(my_portals, {portal_meta, portals}, fn portal, {portal_meta, portals} ->
          tk = Map.get(portal, :tk)
          assigns_key = Map.get(portal, :assigns_key, tk)
          db = Sorcery.Storage.GenserverAdapter.Query.solve_portal(portal, qm)
          {
            [{assigns_key, portal} | portal_meta],
            Map.merge(portals, db)
          }

        end)

        Sorcery.PortalMonitor.monitor(self(), __MODULE__)

        socket
        |> assign(:portals, portals)
        |> assign(:portal_meta, portal_meta)
      end


      def sorcery_unmount(pids) do
        unquote(client).unmount(pids)
      end


      def handle_info("assign_portals", socket) do
        portals = Sorcery.Storage.GenserverAdapter.GetPresence.my_portals(unquote(client), unquote(presence), %{})
        state = unquote(client).get_state(%{})
        {:noreply, assign_portals(socket, portals, state)}
      end


      def src_push!(src) do
        unquote(client).src_push!(src, %{})
      end


    end
  end
end
