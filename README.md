# Sorcery

> "89% of magic tricks are not magic. Technically, they are Sorcery."
> - Portal 2

Your Phoenix LiveViews involve many users, across many pages, all looking at data that may or may not *partiall* overlap. When the data changes anywhere, that specific part of the assigns should be updated for everyone who needs it.

Like having your assigns connected to a private cloud, a (fake) single source of truth that automatically stays synced.

## Installation


```elixir
def deps do
  [
    {:sorcery, "~> 0.1.0"},
  ]
end
```


## Usage
1. Add the helpers to your AppWeb.ex
```elixir
defmodule AppWeb do
  ...
  def live_view do
    quote do
      ...
      # You need to have your own presence module for this to work
      alias AppWeb.Presence 
      unquote(Sorcery.Share.LiveHelper.live_helper())
    end
  end
  ...
end
```

2. Flesh out some 'Subject' functions, for determining what data to watch
3. Subscribe to the subjects in a LiveView
4. The necessary data is now in your assigns. When another user changes that data, it'll update by magic.
```elixir
defmodule MyLiveView do
  use AppWeb, :live_view
  alias Sorcery.Src


  def my_filter(args, db), do: %{user: get_in(db, [:user, args.user_id]}

  def my_query(src) do
    uid = src.args.user_id
    user = App.Repo.one!(...some ecto query...)
    {:ok, %{user: %{uid => user}}}
  end

  @my_subject %Src.Subject{
    filter: &__MODULE__.filter1/2,
    query: &__MODULE__.query1/1,
  }
  
   
  def mount(_, socket) do
    socket = assign(socket, :src, %Src{args: %{user_id: 123, post_id: 44}})
    socket = watch_subject(socket, @my_subject)
  end


  def handle_event("add-like", _, socket) do
    src = Map.get(socket.assigns, :src)

    # First we make changes. Similar to git add / git commit
    src = update_in(src, [:user, src.args.user_id, :likes], fn likes -> likes + 1 end)

    # Then finalize it, and send the updates to everyone who cares
    src = src_push!(src)

    Repo.update!(...update the user in the backend...)
    {:noreply, assign(socket, :src, src)}
  end


  def render(assigns) do
    user = get_in(@src, [:user, @src.args.user_id])
    ~H"""
    <h2>Hello <%= user.name %></h2>
    <p><%= user.likes %></p>
    <button phx-click="add-like">Add Like</button>
    """
  end
end
```
