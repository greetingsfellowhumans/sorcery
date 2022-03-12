# Sorcery

> "89% of magic tricks are not magic. Technically, they are Sorcery."
> - Portal 2

## TLDR
This library allows you to share some assigns data between multiple LiveViews. 

When the data changes it updates all the assigns that watch it.

Think of it like a PubSub, except instead of topic strings, you get queries that can even reference each other.

You don't 'subscribe' to a topic, but open a portal to specific data, and use whatever you see on the other side.

## Setup
See the [setup guide](https://github.com/greetingsfellowhumans/sorcery/blob/master/guides/setup.md)


### Enter, Sorcery
For our example, we look at a simple blog app with User, Post, and Comment tables.

account.settings_live.ex
```elixir
  def mount(_params, session, socket) do
    user_id = # whatever you would normally do to get this
    user = Repo.get(User, user_id)

    # We always need to load in data before it can be shared.
    App.Sorcery.add_entities(:user, [user], %{})

    # Now we configure the portal itself
    # This is basically saying "Watch all :user entities where user.id == user_id"
    portal = %{tk: :user, guards: [{:==, :id, user_id}]}
    App.Sorcery.create_portal(socket, portal, %{})

    # This comes from the live_helper
    # Now we'll get socket.assigns.portals == %{user: %{1 => user}}
    socket = assign_portals(socket)
    
    {:ok, socket}
  end

  def render(assigns) do
  ~H"""
  <h1><%= @portals.user[1].name %></h1>
  """
  end
```


post.comments_live.ex
```elixir
  def mount(_params, session, socket) do
    posts = Repo.all(...)
    comments = Repo.all(...)

    SorceryStorage.add_entities(:post, posts, %{})
    SorceryStorage.add_entities(:comment, comments, %{})

    # First we watch post 1
    post_portal = %{tk: :post, guards: [{:==, :id, 1}]}
    App.Sorcery.create_portal(socket, post_portal, %{})

    # Now we want all comments under post 1
    comment_portal = %{tk: :comment, guards: [{:==, :post_id, 1}]}
    comment_portal_ref = App.Sorcery.create_portal(socket, comment_portal, %{})

    # Until now, everything above could be done with PubSubs.
    # So here's where it gets crazy. Watch closely, as we get the authors for comments.

    author_portal = %{tk: :user, guards: [{:in, :id, {comment_portal_ref, :author_id}}]}
    App.Sorcery.create_portal(socket, author_portal, %{})

    # Ok let's break that down.
    #
    # When we call create_portal/3, it returns a string known as a portal ref.
    # This ref is a hypothetical set of entities.
    # and we want to get a MapSet of each comment.author_id from the previous portal.
    #
    # So to oversimplify it, the author portal is saying:
    #
    # "Watch all :user entities where (user.id in Enum.map(comments, &(&[:author_id])))"

    # As usual, we end by actually assigning those portals so they can be used.
    socket = assign_portals(socket)
    
    {:ok, socket}
  end

  def render(assigns) do
  ~H"""
  <div>
    <%= for comment <- @portals.comment do %>
      <% user = @portals.user[comment.author_id] %>
      <p><%= user.name %></p>
      <p><%= comment.body %></p>
    <% end %>
  </div>
  """
  end
```

Now you're thinking with portals!

## Mutating data
So how do you actually make changes? 

Here we want to add a :like to one of the comments.
```elixir
def handle_event("inc_likes", %{comment_id: comment_id}, socket) do
  args = %{} # Ignore this for now, we'll come back to it in the interceptors section...

  # We create a %Sorcery.Src{} struct to update the Source upon which all portals depend.

  src = Src.new(socket.assigns.portals, args)
        |> update_in([:comment, comment_id, :likes], fn likes -> likes + 1 end)

  # Now use the Src!
  # This was included with the live_helper.
  src_push!(src)

  {:noreply, socket}
end

```
As soon as those changes are finished, every portal that should care about that comment will get the update.

By the way, we're using the Sorcery.Ecto adapter here, so it will actually send those changes to the database in a transaction.
Eventually I would like to make it so you can either skip that, or implement your own adapter.

## Src
Src is the original reason for the name Sorcery.

It was meant to be used for transforming a lot of data in weird ways.
You start by passing in a map of data, in exactly the format the portals come in. Cool coincidence!

Src has two such maps, actually. :original_db, and :changes_db (which starts its life as %{})

As you might have guessed, Src implements Access, so you can simply use get_in, put_in, etc.
Those functions will target the most up-to-date data possible, whether that means data from changes, or original, or even a combination.

It also implements Enumerable which you can use like: Enum.map(src, fn {tk, id, entity} -> ...end)

One of the interesting use cases might be if you are doing a transaction in which you insert some data, and need to refer to the new data.

Behold the :inserts and :deletes fields!
```elixir
%Src{
    deletes: [{:post, 1}],
    inserts: %{
        post: %{
            "$sorcery:1" => %{title: "Hello"}
        }
    },
    original_db: ...,
    changes_db: %{
        comment: %{
            50 => %{post_id: "$sorcery:1"}
        }
    }
}
```
In a single transaction, this Src will:
- Delete Post with id: 1
- Create a new post with title "Hello"
- Change existing comment with id: 50, to have a post_id pointing at the post we just made.

Note the string "$sorcery:1" is a placeholder. The "1" isn't important, you could just as easily have "$sorcery:magic! WHOAAAA =-D"
As long as it starts with "$sorcery:"


## Interceptors
These are functions that take a Src and return a Src.
They are meant to be piped together for a series of transformations when a normal pipeline won't cut it.

Along the way, they may or may not stop the pipeline, change the list of interceptors on the fly, etc.
You can even do TIME TRAVEL!

Simple example of an interceptor that increments a like for the current comment
(Now we're finally using Src :args passed as the second argument of Src.new/2)
```elixir
def intercept(%{args: %{comment_id: comment_id}} = src) do
  update_in(src, [:comment, comment_id, :likes], fn likes -> likes + 1 end)
end
```

Here's one that will stop all future interceptors, if likes > 100, by setting the :interceptors list to empty.
```elixir
def intercept(%{args: %{comment_id: comment_id}} = src) do
  likes = get_in(src, [:comment, comment_id, :likes])
  if likes > 100 do
    Map.put(src, :interceptors, []) 
  else
    src
  end
end
```

Here's one that will go back in time by 2 interceptors, and change the comment we're working on, if likes > 100.

Do be careful to change something so you don't end up in an infinite loop. Didn't your mother ever tell you that time travel is dangerous?
```elixir
def intercept(src) do
  %{comment_id: comment_id} = src.args
  likes = get_in(src, [:comment, comment_id, :likes])
  if likes > 100 do
    src
    |> Src.time_backward(2)
    |> put_in([:comment, 25, :likes], 0) # Just to be safe
  else
    src
  end
end
```
There is also a Src.time_forward/2 function which is far safer. It just skips the next (n) interceptors in the list.
