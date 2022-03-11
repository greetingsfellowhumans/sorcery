# Sorcery

> "89% of magic tricks are not magic. Technically, they are Sorcery."
> - Portal 2

Like a PubSub, but better.

Sorcery feels like having your LiveView assigns connected to a private cloud, a (fake) single *source* of truth that automatically stays synced with other users and LiveViews. 
Replacing topic strings with more powerful query and filter functions to subscribe to precisely the data you need.


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

Ok, fine, we can just pile on a bunch of logic. For example, every time a user updates, you could find all their comments, and broadcast to each `authors_of_comments:#{comment.post_id}` or something :-\
And every LiveView subscribing will need some handle_info for sorting it out.

It's an ugly, non-performant solution. This should be self evident. How can we blame the intern...


### Enter, Sorcery
Instead of a PubSub with topics, we use Sorcery with Portals.

account.settings_live.ex
```elixir
  def mount(_params, session, socket) do
    # however you normally get this
    user_id = ... get_user(socket)
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
