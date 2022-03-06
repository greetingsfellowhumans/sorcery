defmodule Sorcery.Storage.GenserverAdapterTest do
  use ExUnit.Case, async: true
  use Norm
  alias Sorcery.Portal
  #alias Sorcery.Storage.GenserverAdapter
  alias Sorcery.Storage.GenserverAdapter.{Client, Specs}
  #alias Sorcery.Specs.Primative, as: T
  #alias Sorcery.Specs.Portals, as: PortalT
  alias Sorcery.Entities.{User, Post, Comment}
  alias Sorcery.Storage.PresenceMock, as: Presence

  @li_users [
    %User{id: 1, name: "Aaron", karma: 5},
    %User{id: 2, name: "Not Aaron", karma: 15},
    %User{id: 3, name: "Someone else", karma: 105}
  ]

  @li_posts [
    %Post{id: 10, title: "Post 1", body: "Something good", author_id: 1, views: 25},
    %Post{id: 20, title: "Post 2", body: "Something bad", author_id: 2, views: 50}
  ]

  @li_comments [
    %Comment{id: 100, post_id: 10, body: "That was really good", author_id: 2, likes: 25},
    %Comment{id: 200, post_id: 20, body: "That was really bad", author_id: 3, likes: 50}
  ]

  @post_portal_spec %{tk: :post, guards: [{:==, :id, 10}], indices: [:author_id]}

  def comment_portal_spec(post_ref) do
    %{tk: :comment, guards: [{:in, :post_id, {post_ref, :id}}], indices: [:post_id, :author_id]}
  end

  def author_portal_spec(comment_ref, post_ref) do
    %{tk: :user, guards: [
      {:or, [
        {:in, :id, {post_ref, :author_id}},
        {:in, :id, {comment_ref, :author_id}}
      ]}
    ]}
  end

  test "Startup state" do
    opts = %{name: :startup_test}
    p = start_supervised!({Client, name: opts[:name]})
    assert is_pid(p)
    assert conform!(Client.get_state(opts), Specs.client_state())
  end


  test "Loading Entities" do
    opts = %{name: :loading_entities_test}
    _p = start_supervised!({Client, name: opts.name})
    state_before = conform!(Client.get_state(opts), Specs.client_state())
    Client.add_entities(:user, [%User{id: 1, name: "Aaron", karma: 5}], %{name: opts.name})
    state_after = conform!(Client.get_state(%{name: opts.name}), Specs.client_state())
    assert state_before.db != state_after.db
  end


  test "Create Portal Map" do
    p1 = Portal.new(%{tk: :user, guards: [{:==, :id, 1}]})
    assert p1.indices == %{id: MapSet.new()}

    p2 = Portal.new(%{tk: :user, guards: [{:==, :id, 1}], indices: [:karma]})
    assert p2.indices == %{id: MapSet.new(), karma: MapSet.new()}

    p3 = Portal.new(%{tk: :user, guards: [{:==, :id, 1}], indices: nil})
    assert p3.indices == %{id: MapSet.new()}
  end

  test "Basic Portal Crud" do
    presence_pid = start_supervised!({Presence, %{}})
    opts = %{name: :portal_crud, pid: presence_pid}
    _client = start_supervised!({Client, opts})

    Client.add_entities(:user, @li_users, opts)
    Client.add_entities(:post, @li_posts, opts)
    Client.add_entities(:comment, @li_comments, opts)

    post_portal_ref = Client.create_portal(presence_pid, @post_portal_spec, opts)
    post_table = Client.view_portal(post_portal_ref, :post, opts)
    assert post_table[10].title == "Post 1"
  end



  test "Advanced Portal Crud" do
    presence_pid = start_supervised!({Presence, %{}})
    opts = %{name: :portal_crud, pid: presence_pid}
    _client = start_supervised!({Client, opts})

    Client.add_entities(:user, @li_users, opts)
    Client.add_entities(:post, @li_posts, opts)
    Client.add_entities(:comment, @li_comments, opts)

    post_portal_ref = Client.create_portal(presence_pid, @post_portal_spec, opts)
    comment_spec = comment_portal_spec(post_portal_ref)
    comment_portal_ref = Client.create_portal(presence_pid, comment_spec, opts)
    _comment_table = Client.view_portal(comment_portal_ref, :comment, opts)

    author_spec = author_portal_spec(comment_portal_ref, post_portal_ref)
    author_portal_ref = Client.create_portal(presence_pid, author_spec, opts)
    author_table = Client.view_portal(author_portal_ref, :user, opts)
     
    Process.sleep(150) # Might have a race condition in the tests. Investigate later.
    assert Map.keys(author_table) == [1, 2]
  end




end
