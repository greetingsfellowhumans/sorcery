# Sorcery

A framework which rethinks how data flows, and how we build apps.

Plays nicely with Phoenix LiveViews, or can be used alone.

The philosophy of Sorcery:

```
A database has a table called People.

There are 3 different web pages that all display *some* data about the row where People.id == 1
No matter where this person appears, they are always the same entity.

If they change their name in one place, it should automatically update their name in EVERY place that it appears.

This should be the DEFAULT way of building an app. 
I don't want to setup a Phoenix.Channel, nor a PubSub.
I don't have time to wire this up in every page where I want it to happen.
It should be automatic.

We should not even need to think about it. I use an entity in a page, and it should stay up to date forever. Period.
```


## How does it work
Sorcery comes with it's own headless, reversible, query language (SrcQL). By default it uses Ecto and whatever backend you want (Postgres, etc.). 
You run the query and get a 'Portal' which is like a little wormhole showing whatever database entities match the Query.

Here we see it in LiveViews, but any GenServer can do this.
The query lists several 'Logic Variables' or 'Lvars', and we are looking at one called "?all_players"

```elixir
~H"""
  <%= for %{id: id, health: health, name: name} = _player <- portal_view(@sorcery, :my_portal, "?all_players") do %>
    <p><%= id %> | <%= name %>'s health: <%= health %></p>
  <% end %>
"""
```

If someone new enters the room, you'll see the change instantly. Ditto if someone leaves, or changes their name, or anything like that.


So a Portal is almost like a PubSub, if a PubSub had access to a full featured language, and the ability to recursively watch OTHER PubSubs.


## Performance
Memory hog with almost no latency.

All entities being watched are cached in mnesia tables. So often this allows us to skip calling the database, and use cache.


## Installation


```elixir
def deps do
  [
    {:sorcery, "~> 0.3.0"},
  ]
end
```

Then run the following to get bootstrapped
```bash
$ mix deps.get
$ mix sorcery.init
```

Several files were just created in your app under /lib/src

Make sure to also open your `application.ex` and add
```elixir
children = [
  # Just an example, but you need to add each of your PortalServers here.
  {Src.PortalServers.Postgres, name: Src.PortalServers.Postgres},

  # This is mandatory.
  {Src, []},
]
```

The next thing you should do is create some schemas, and queries. 
