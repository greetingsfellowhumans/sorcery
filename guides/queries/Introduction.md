# Introduction

Sorcery Query Language is a reversible query language. Please don't call it SQL, that would be confusing for some reason. SrcQL will do fine.

The syntax is partially inspired by Datalog, which is used by the Datomic database. But there are many important differences, and it is not intended to be identical.

## Basic Usage

As a quirky example, we are making a multiplayer game in which there are players, organized into teams, and each player is a wizard who casts spells. They can all battle in an 'arena'
So the four tables are: team, player, spell, arena

Now suppose we want a query that pulls up data for arena 1 

```elixir
# Don't try to fully understand this yet. We're going to break it down soon and explain it line by line.

alias Sorcery.Query, as: SrcQL
SrcQL.new(%{
  where: [
    {"?arena",   :arena,   :id, 1}, 
    {"?teams",   :team,    :current_arena_id, "?arena.id"}
    {"?players", :player,  :team_id, "?teams.id"}
    {"?players", :player,  :health, {:>, 0}}
    {"?spells",  :spell,   :player_id, "?players.id"}
  ],
  find: %{
    "?players" => [:name, :health, :team_id]
    "?spells" =>  [:name, :energy, :type, :player_id]
  }
})


# => eventually fetches a map like
%{
    "?players" => %{
        2 => %{id: 2, name: "Jose", health: 100, team_id: 1},
        85 => %{id: 85, name: "Aaron", health: 10, team_id: 2},
        ...
    },
    "?spells" => %{
        123 => %{id: 123, name: "Heal", energy: 2, player_id: 85, type: "white"},
        254 => %{id: 254, name: "Fire", energy: 5, player_id: 2, type: "red"},
        ...
    },
}
```

So you might have guessed the list of :where tuples is similar to something you might find in SQL. Just a list of conditions for filtering data. Except the tuples look weeeeiiird.

```elixir
  # each tuple has 4 elements in it.
  # {lvar,     tk,       attr,  value}
  {"?arena",   :arena,   :id,   1}, 
```
The string `"?arena"` is a logic variable, or Lvar for short.
it represents a lazy Set of entities of a specific type. in this case they are all :arena entities.
The attr/value pair helps us limit the set of matches. Now every entity in the ?arena set must have an :id of 1. 
So how big is the set going to be? Either 0 or 1.

Let's continue.

```elixir
  # Now the final element (the value) is referencing a previous lvar... and appending ".id" to the end of it.
  # If you imagine gettings all the possible ids from ?arena, i.e. ids = Enum.map(?arena, &(&1.id))
  # And then we are basically running Enum.filter(?teams, &(&1.current_arena_id in ids))
  {"?teams",   :team,    :current_arena_id, "?arena.id"}
```
Ah yes, our first inferred join. Instead of a JOIN...ON syntax, we just do this and it works like ~~magic~~ sorcery.


```elixir
  # Boring, you know this one already.
  {"?players", :player,  :team_id, "?teams.id"}

  # Ahh now we bring operators into the mix!
  # So we only get players who are members of at least one of the ?teams...
  # But they ALSO must not be dead. Makes it hard to play. So it filters player.health > 0
  {"?players", :player,  :health, {:>, 0}}
```

But what about :find? Well it's kind of like if a SQL select statement made a baby with Map.take/2.
Note that it automatically adds an :id field to every take... and the format returned is a map in a pretty specific shape.
```elixir
find: %{"?foo" => [:name] }

# lvar => %{id => entity}

selection = %{
    "?foo" => %{
        1 => %{id: 1, name: "some name"}
    }
}
```

@TODO have the option to exclude :id fields.

@TODO have the option to use a different primary key than :id.


## Function syntax
What if I told you the :where tuples were actually just a shorthand for a more detailed syntax?

Let's rewrite the query


```elixir

alias Sorcery.Query, as: SrcQL
SrcQL.new(%{
  where: [
    SrcQL.Clause.new(%{lvar: "?arena", tk: :arena, filters: [%{attr: :id, val: 1, op: :==}]}),
    SrcQL.Clause.new(%{lvar: "?teams", tk: :team,  filters: [%{attr: :team_id, lvar: "?arena", lvar_attr: "id", op: :in}] }),
    SrcQL.Clause.new(%{lvar: "?players", tk: :player, filters: [
      %{attr: :team_id, lvar: "?arena", lvar_attr: "id", op: :in},
      %{attr: :health, val: 0, op: :>}
    ]}),
    SrcQL.Clause.new(%{lvar: "?spells", tk: :spell, filters: [%{attr: :player_id, lvar: "?players", lvar_attr: "id", op: :in}]}),
  ],
  find: %{
    "?players" => [:name, :health, :team_id]
    "?spells" =>  [:name, :energy, :type, :player_id]
  }
})
```
These functions return structs %SrcQL.Clause{...}
As do the tuples. It's all the same.

Now why on earth would you want this? Well you probably don't want to do it manually. But it's useful to know, because there are also other structs available, for different types of clauses!

```elixir
# This will get all foo entities with :magic greater than 100, OR with an id of 42.
SrcQL.OrClause.new(%{lvar: "?foo", tk: :foo, filters: [
  %{attr: :id, val: 42},
  %{attr: :magic, val: 100, op: :>},
]})
```
There is no need for an AndClause, because the default Clause does that.

You can also do certain aggregation operations.

```elixir
# This will get the average health of all entities matching "?players"
SrcQL.Aggregate.Mean.new(%{lvar: "?avg_health", val: "?players.health"})
```
