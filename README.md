# Sorcery

> "89% of magic tricks are not magic. Technically, they are Sorcery."
> - Portal 2

## TLDR
This library allows you to share some assigns data between multiple LiveViews. 

When the data changes it updates all the assigns that watch it.

Think of it like a PubSub, except instead of topic strings, you get queries that can even reference each other.

You don't 'subscribe' to a topic, but open a portal to specific data, and use whatever you see on the other side.

## A real life case study 
### The problem this solves
Say you have a classic blog App with Users, Posts, and Comments.

User alice is on "/posts/52" rendered by a LiveView
She can see the body of the Post, all the Comments, and the names of Users writing Comments.

Another User, joe, is on his own Account.Settings LiveView. 
He decides to change his name to "The JoeMeister". 
Thanks to Phoenix LiveViews, he sees his name update instantly! #magic

But Alice, reading his comment on another page, doesn't get the update.

Ok, so you implement a PubSub, subscribing her to a topic like `user:#{joe.id}` for every user in mount/3.

But wait... You don't really want a new PubSub topic for every user posting a comment, right?

So maybe you have a topic like `authors_of_comments:#{post_id}`

Better, but what would happen if a user registers to the site AFTER alice visits the page, and THEN change their name. Alice still wouldn't be subscribed to them.

Ok, fine, we can just pile on a bunch of logic. For example, every time a user updates, you could find all their comments, and broadcast to each `authors_of_comments:#{comment.post_id}`, or... something...? :-\
And every LiveView subscribing will need some handle_info for sorting it out.

It's an ugly, non-performant solution. This should be self evident. How can we blame the intern...


### Enter, Sorcery
Instead of a PubSub with topics, we use Sorcery with Portals.

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
    socket = assign_portals(socket)
    # socket.assigns.portals == %{user: %{1 => user}}
    
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

Here we want to add a like to one of the comments.
```elixir
def handle_event("inc_likes", %{comment_id: comment_id}, socket) do
  args = %{} # Ignore this for now...

  # We create a %Sorcery.Src{} struct to update the Source upon which all portals depend.

  src = Src.new(socket.assigns.portals, args)
        |> update_in([:comment, comment_id, :likes], fn likes -> likes + 1 end)

  # Now use the Src!
  # This was included with the live_helper.
  src_push!(src)

  {:noreply, socket}
end

# As soon as those changes are finished, every portal that should care about that comment will get the update.

```

## Src
Src is the original reason for the name Sorcery.

It was meant to be used for transforming a lot of data in weird ways.
You start by passing in a map of data, in exactly the format the portals come in. Cool coincidence!

Src has two such maps, actually. :original_db, and :changes_db (which starts life its empty %{})

As you might have guessed, it implements Access, so you can simply use get_in, put_in, etc.
Those functions will target the most up-to-date data possible, whether that means data from changes, or original.

## Interceptors
These are functions that take a Src and return a Src.
They are meant to be piped together for a series of transformations when a normal pipeline won't cut it.

Along the way, they may or may not alter some metadata, which could potentially stop the pipeline, change the list of interceptors on the fly, etc.
