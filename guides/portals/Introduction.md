# Introduction

Portals are what tie it all together. The connective tissue of Sorcery. But first we have one other concept to talk about.

## PortalServers

A PortalServer is an elixir process which has access to a data store. When you send a SorceryQuery to a PortalServer, you don't *just* get some data back... you create a Portal, with a continuous feed of data matching that query. Kind of like a PubSub on steroids.

The PortalServer holds all the configuration, describing in detail HOW the data is accessed. 

Here you can throw in your own custom adapters for different databases. 

You can tell it to pass messages via REST and GraphQL or elixir's Process.send

As long as you find/build the right adapters, the options are limitless.

## Fun examples of PortalServers to get your brain juices flowing:

| PortalServer      | Data Store                  |
| ---               |  ---                        |
| Phoenix.LiveView  |  assigns.sorcery            |
| GenServer         |  a map in the state         |
| GenServer         |  Repo connected to Postgres |
| GenServer         |  ANOTHER PortalServer       |
| A plain Process   |  An external weather API    |

Do you see how flexible it is? Very. I believe one could technically have a PortalServer fire off an email, which someone manually responds to with an attachment... as long as you write an adapter for it, and don't care about latency, it would work.

## LiveView

This gets special mention because it was the original use case, and reason for creating Sorcery.

```elixir
  def mount(_, _, socket) do
    socket = socket
             |> Sorcery.PortalServer.create()
             |> Sorcery.Portal.open(to, sorcery_query)
    {:ok, socket}
  end

  def handle_info({:sorcery, msg}, socket), do: Sorcery.PortalServer.live_view_handler(msg, socket)
```

That is all we need to do to turn a LiveView into a PortalServer. And just for fun, we also open up a Portal to some other PortalServer. See the guides on Queries and LiveViews for more detail.

Note that there will be times when this LiveView receives all sorts of whacky messages from whatever other PortalServers it connects to. You don't need to care about those whatsoever, they will all be tagged as {:sorcery, _}

Now you can obviously intercept those and look at them with IO.inspect, or dbg, just for fun. But you do not need to know what's going on behind the curtain. I am a powerful wizard, you can trust me.
