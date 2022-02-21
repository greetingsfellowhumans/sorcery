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
Instead of a PubSub with topics, we use Sorcery with Subjects.

Joe and Alice will be using different subjects, but if any of the data overlaps, at any point in time, then the correct data will be dispatched and merged with the assigns.

- No custom handlers
- No coordination
- Not *too much* boilerplate

The Account.Settings mount might include a subject like 
```
%Subject{
  query: fn %{args: %{user_id: uid}} -> {:ok, %{users: %{uid => Repo.get!(User, uid)}} } end, 
  filter: fn args, db -> %{users: get_in(db, [:users, args.user_id]} end
}
```
While the Post.Comments mount might break it into several subjects
```
[
%Subject{
  query: fn %{args: %{post_id: post_id}} -> {:ok, %{
    posts: get_post(post_id),
    comments: get_comments(post_id),
    users: get_authors(post_id)
  } } end, 
}
%Subject{
  filter: fn 
    args, %{comments: comments} ->
      comments = Enum.filter(comments, fn c -> c.post_id == args.post_id end)
      authors = 
    _args, _db -> %{}
  end
}
]


Post.Comments
gql`
  posts(id: @post_id) {
    id
    title
    body
  }

  comments(post_id: @post_id) { _ } 

  users(fn u, %{comments: comments, users: users} ->  
     u.id in Enum.map(comments, &(&1.user_id)) 
  end) {
    name
  }
`

Account.Settings
gql `
  users(id: @user_id) {
    name
    email
  }
`

================
Datalog

Post.Comments
find: [
  [:posts, post_id, :id],
  [:posts, post_id, :title],
  [:posts, post_id, :body],
  [:comments, comment_id, _],
  [:users, uid, :name],
], where: [
  [:posts, ^args.post_id, :id, post_id],
  [:comments, comment_id, :post_id, post_id],
  [:comments, comment_id, :author_id, uid_id],
  [:users, uid, :id, uid]
]

Account.Settings
find: [
  [:users, uid, :name],
  [:users, uid, :email],
],
where: [
  [:users, uid, :id, ^args.user_id]
]


===============
Custom Repo





```

### Topics are more granular and flexible
With a PubSub, you get a string topic, and probably need to come up with your own system of handling arguments, like `room:1` or `page?foo=1&bar=42`
But what if multiple topics *partially* overlap? E.g. One LiveView is watching `user:1`, while another is watching `authors_of_comments:123`, which happens to include user 1... If you change the name of user 1, you want both LiveViews to automatically get the update.

With sorcery you build a Subject struct with one or two fields. A :query function that grabs the initial data from ecto/an api/etc. And a :filter function that receives data as it changes, and determines what data, if any, it needs to care about.

You build these functions however you want, there are no limits, as long as the return value is formatted correctly

### Ease of use
A lot of boilerplate is taken care of. 
1. You subscribe with a single function `watch_subject(socket, %Subject{})`
2. When data is changed, you push the changes with a single function `src_push!/1` (Think of it like a powerful 'Force Push' kinda move).
3. To receive changes... do nothing. Your assigns are already updated, and your LiveView will change with it.

### Handling disconnects
You will still need to create your own Presence module and alias it in your `app_web.ex`. After that Sorcery will take care of everything.
When nodody cares about a piece of data anymore, it no longer takes up memory.


## Usage
A simple LiveView example, tracking 4 different Subjects

```elixir
defmodule MyLiveView do
  use AppWeb, :live_view
  alias App.MySubjects, as: Subs

  
  def mount(_, _, socket) do
    socket = init_sorcery(socket, %{
      args: %{user_id: 123, post_id: 44}
      subjects: [Subs.user_profile, Subs.posts_by_user, Subs.comments_on_posts, Subs.authors_of_comments]
    })

    {:noreply, socket}
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


  # Access the data using get_in(@src ...) to automatically track the most up to date stuff.
  # If you try using dot syntax, it probably won't work because there is a lot going on in the background.
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

## One-Time setup
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

## Installation


```elixir
def deps do
  [
    {:sorcery, "~> 0.1.0"},
  ]
end
```

