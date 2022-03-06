defmodule Sorcery.Share.LiveHelper do
  defmacro __using__([client: client, presence: presence]) do
    #quote bind_quoted: [client: client, presence: presence] do
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
            Map.put(portals, assigns_key, db[tk])
          }

        end)

        socket
        |> assign(:portals, portals)
        |> assign(:portal_meta, portal_meta)
      end

      def handle_info("assign_portals", socket) do
        portals = Sorcery.Storage.GenserverAdapter.GetPresence.my_portals(unquote(client), unquote(presence), %{})
        state = unquote(client).get_state(%{})
        {:noreply, assign_portals(socket, portals, state)}
      end



      #def watch_subject(socket, %Sorcery.Src.Subject{} = sub) do
      #  Presence.track(self(), "src_subjects", "src_subjects", %{pid: self(), subject: sub})
      #  src = Map.get(socket.assigns, :src, %Sorcery.Src{})
      #  subs = src.subjects
      #  src = Map.put(src, :subjects, [sub | subs])
      #  src = case Sorcery.Src.Subject.fulfill_all(src) do
      #    %Sorcery.Msg{status: :ok, body: body} -> Map.put(src, :original_db, body)
      #    msg -> Map.put(src, :msg, msg)
      #  end
      #  assign(socket, :src, src)
      #end
      #def watch_subject(socket, attrs) do
      #  sub = struct(Sorcery.Src.Subject, attrs)
      #  watch_subject(socket, sub)
      #end


      #def handle_info(%{msg: "src_pull", src: %{deletes: del, changes_db: ch, original_db: og}}, socket) do
      #  # 1. merge new changes with socket origin
      #  case Map.get(socket.assigns, :src) do
      #    nil -> {:noreply, socket}
      #    src ->
      #      db = Map.merge(og, ch)
      #      # 2. remove deleted
      #      db = Sorcery.Src.Utils.remove_dels_from_db(db, del)

      #      # 3. apply subject filters
      #      db = Sorcery.Src.Subject.filter_db(db, src)

      #      # 4. Return
      #      src = src
      #        |> Map.put(:original_db, db)
      #        |> Map.put(:changes_db, %{})
      #        |> Map.put(:deletes, [])
      #      {:noreply, assign(socket, :src, src)}
      #  end
      #end


      #def handle_info(%{msg: "src_push", src: src}, socket) do
      #  presences = Presence.list("src_subjects")
      #  pids = Sorcery.Share.Watch.get_pids_from_changes(src, presences) |> MapSet.delete(self())
      #  for pid <- pids do
      #    send(pid, %{msg: "src_pull", src: src})
      #  end
      #  %{original_db: og, changes_db: ch, deletes: del} = src
      #  db = Map.merge(og, ch) |> Sorcery.Src.Utils.remove_dels_from_db(del)
      #  src = src
      #        |> Map.put(:original_db, db)
      #        |> Map.put(:changes_db, %{})
      #        |> Map.put(:deletes, [])

      #  {:noreply, assign(socket, :src, src)}
      #end


      #def push_src!(src) do
      #  send(self(), %{msg: "src_push", src: src})
      #end

      


    end
  end
end
