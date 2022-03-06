# Setup
Unfortunately there are a few steps you must take to get up and running.

1. Add to mix.exs deps

2. `mix deps.get`

3. Create a phoenix presence module if you haven't already.
```elixir
defmodule AppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :app,
    pubsub_server: App.PubSub
end
```

4. Create a module like `App.Sorcery`.
```elixir
defmodule App.Sorcery do
  alias App.Accounts.User
  alias App.Customers.{Location, Unit}

  @tables %{
    tech: %{schema: User, index: [:user_id]},
    unit: %{schema: Unit},
    location: %{schema: Location, index: [:location_type]},
  }

  use Sorcery.Storage.GenserverAdapter, %{
    presence: AppWeb.Presence,
    repo: App.Repo,
    ecto: Ecto,
    tables: @tables,
  }
end
```

5. Add those modules to the supervision tree.
```application.ex
children = [
  {Phoenix.PubSub, name: App.PubSub},

  AppWeb.Presence, # Must comme AFTER PubSub

  App.Sorcery, # Must come AFTER presence
]

```

6. Prepare your schemas
Sorcery expects every schema module to implement the functions `sorcery_update/2` and `sorcery_insert/2`

Both must take a struct and attrs, and return a changeset.
```elixir
# App.Accounts.User

def sorcery_update(user, attrs \\ %{}) do
  user
  |> cast([:name], attrs)
end

def sorcery_insert(user, attrs \\ %{}) do
  user
  |> cast([:name], attrs)
end
```

You must do this for every entity type you wish to track with portals, and update with Src.

And don't forget to pass the schema into the App.Sorcery tables configuration.

7. Add the LiveView helpers to your `app_web.ex`
```elixir
...
def live_view do
  quote do
    use Phoenix.LiveView, ...

    use Sorcery.LiveHelper,
      client: App.Sorcery,
      presence: AppWeb.Presence
  end
end
```
