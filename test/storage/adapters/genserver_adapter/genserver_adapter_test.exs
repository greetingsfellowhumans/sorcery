defmodule Sorcery.Storage.GenserverAdapterTest do
  use ExUnit.Case, async: true
  use Norm
  alias Sorcery.Portal
  alias Sorcery.Storage.GenserverAdapter
  alias Sorcery.Storage.GenserverAdapter.{Client, Specs, ViewPortal, UpdatePortal, GetPresence}
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PortalT
  alias Sorcery.Entities.{User, Post, Comment}
  alias Sorcery.Storage.PresenceMock, as: Presence


  test "Startup state" do
    opts = %{name: :startup_test}
    p = start_supervised!({Client, name: opts[:name]})
    assert is_pid(p)
    state = conform!(Client.get_state(opts), Specs.client_state())
  end


  test "Loading Entities" do
    opts = %{name: :loading_entities_test}
    p = start_supervised!({Client, name: opts.name})
    state_before = conform!(Client.get_state(opts), Specs.client_state())
    Client.add_entities(:user, [%User{id: 1, name: "Aaron", karma: 5}], %{name: opts.name})
    state_after = conform!(Client.get_state(%{name: opts.name}), Specs.client_state())
    assert state_before.db != state_after.db
  end


  test "Creating Portals" do
    client_opts = %{name: :create_portals_test_client}
    socket = %{assigns: %{}}

    # So the presence returns and uses a pid
    pres = start_supervised!({Presence, %{}})
    pres_opts = Map.put(client_opts, :pid, pres)
    assert %{} == Agent.get(pres, fn s -> s end)

    # But the client uses the name in the options
    client = start_supervised!({Client, client_opts})
    assert Client.get_state(client_opts).db.user == %{}

    li_users = [
      %User{id: 1, name: "Aaron", karma: 5},
      %User{id: 2, name: "Not Aaron", karma: 15},
      %User{id: 3, name: "Someone else", karma: 105}
    ]
    Client.add_entities(:user, li_users, client_opts)
    new_portal = Portal.new(%{tk: :user, pid: self(), guards: [{:==, :id, 1}]})
    socket = Client.create_portal(pres, new_portal, pres_opts)
    Process.sleep(100)

    #Presence.track(self(), "portals:user", new_portal.id, new_portal, %{name: pres})
    m = Presence.list("portals:user")
    portal_map = Map.from_struct(new_portal)
    assert Map.get(m, new_portal.id) == %{metas: [%{pid: self(), portal: portal_map}]}

    viewed = ViewPortal.view_portal(new_portal, Client.get_state(client_opts))
    assert %{1 => %{id: 1, karma: 5, name: "Aaron"}} == viewed

    assert conform!(viewed, T.tablemap())

    portal = UpdatePortal.add_indices(new_portal, Client.get_state(client_opts))
    assert MapSet.new([1]) == portal.indices.id

    # Let's get more dynamic portals now
    li_posts = [
      %Post{id: 10, title: "Post 1", body: "Something good", author_id: 1, views: 25},
      %Post{id: 20, title: "Post 2", body: "Something bad", author_id: 2, views: 50}
    ]
    li_comments = [
      %Comment{id: 100, post_id: 10, body: "That was really good", author_id: 1, likes: 25},
      %Comment{id: 200, post_id: 20, body: "That was really bad", author_id: 3, likes: 50}
    ]
    Client.add_entities(:post, li_posts, client_opts)
    Client.add_entities(:comment, li_comments, client_opts)

    post_portal = Portal.new(%{tk: :post, pid: self(), guards: [{:==, :id, 10}]})
    socket = Client.create_portal(pres, post_portal, pres_opts)
    #viewed = ViewPortal.view_portal(portal, Client.get_state(client_opts))

    #comment_portal = Portal.new(:comment, self(), [{:in, :post_id, {post_portal, :id}}])

    portals_list = GetPresence.my_portals(Client, Presence, client_opts)
    assert conform!(portals_list, coll_of(PortalT.portal()))

    post_portal = GetPresence.get_portal(Presence, portal.id, client_opts)
    assert conform!(post_portal, PortalT.portal())
    #assert my_portals == pres1
  end


#  #test "Mock Presence" do
#  #  #{:ok, pid} = Presence.start_link()
#  #  #assert is_pid(pid)
#  #end


end
