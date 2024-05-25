## LiveViews

Let's start with the minimalistic demo module for a LiveView, and explain it afterward

```elixir
defmodule MyAppWeb.SandboxLive do
  use Phoenix.LiveView
  use Sorcery.LiveHelpers  # <- This adds functions like spawn_portal/2 etc.

  def mount(_param, _sesh, socket) do
    socket = 
      socket
      |> initialize_sorcery(%{
        sorcery_module: MyApp.Sorcery # We talk about this module in the Introduction guide
      })

      # You can call this multiple times with different config
      # As long as the portal_name is unique on a per-liveview basis.
      |> spawn_portal(%{
        portal_name: :battle_portal, # whatever atom you want
        portal_server: MyApp.Sorcery.PortalServers.Postgres, # See the PortalServer guide
        query_module: MyApp.Sorcery.Queries.GetBattle, # See the Queries guide
        query_args: %{player_id: 1} # this will be passed into the query eventually
      })

    {:ok, socket}
  end


  def handle_event("change_hp", %{"id" => idstr, "amount" => amountstr}, socket) do
    id = String.to_integer(idstr)
    amount = String.to_integer(amountstr)

    # Every mutation requires a portal
    Sorcery.Mutation.init(socket.assigns.sorcery, :battle_portal)
    |> Sorcery.Mutation.update([:player, id, :health], fn _old_health, health -> health + amount end)
    |> Sorcery.Mutation.send_mutation()
        
    {:noreply, socket}
  end


  def render(assigns) do
    ~H"""
      <%= for %{id: id, health: health, name: name} = _player <- portal_view(@sorcery, :battle_portal, "?all_players") do %>
        <p><%= id %> | <%= name %>'s health: <%= health %></p>
        <button style="background: #595" phx-click="change_hp" phx-value-amount={1} phx-value-id={id}>Heal</button><br/>
        <button style="background: #955" phx-click="change_hp" phx-value-amount={-1} phx-value-id={id}>Harm</button><br/>

      <% end %>
    """
  end


end
```

