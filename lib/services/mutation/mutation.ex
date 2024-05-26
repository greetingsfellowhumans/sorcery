defmodule Sorcery.Mutation do
  @moduledoc """
  This is the interface for creating changes in Sorcery.
  Mutations have some similarities to Ecto Changesets in the sense that we are building a struct that defines all the changes without actually applying them.
  But there are many differences, as you will soon see.

  You start by creating the initial mutation with a portal.

  Then you apply all the changes you want to the data in that portal.

  At first nothing happens! This is because you must send the mutation up to the parent PortalServer.

  After it applies the changes, it will dispatch them back down to any child PortalServers that care about any of the entities involved.
  This is where the magic of Sorcery really comes in. Under the hood, we are doing some pretty efficient reverse queries, in parallel, to figure out where to send the data.

  All the PortalServers will update their Portals accordingly.

  ```elixir
  iex> alias Sorcery.Mutation, as: M
  iex> m = M.init(socket.assigns.sorcery, :my_portal)
  iex> m = M.update(m, [:player, 1, :age], fn _original_age, latest_age -> latest_age + 1 end)
  iex> m = M.put(m, [:player, 1, :health], 100)
  iex> # Avoid this in real life, the value could be different by time the mutation reaches the PortalServer
  iex> player = M.get(m, [:player, 1])
  iex> player.health
  100
  iex> ### We can also use placeholder ids so that new entities (which haven't even been created yet) can be referenced by other entities.
  iex> m = M.create_entity(m, :team, "?my_new_team", %{name: "My New Team"})
  iex> m = M.put(m, [:player, 1, :team_id], "?my_new_team.id")
  iex> player = M.get(m, [:player, 1])
  iex> player.team_id
  "?my_new_team.id"
  iex> # This string is of course, the placeholder. But after we actually run the mutation, the team is created with a normal integer id.
  iex> # The parent PortalServer creates the new team entity, it will automatically replace all calls to "?my_new_team" with that entity.
  iex> Sorcery.Mutation.send_mutation(m)
  iex> # ... a few milliseconds later, after receiving the update
  iex> player = portal_view(@sorcery, :my_portal, "?all_players")[1]
  iex> new_team_id = player.team_id
  iex> is_integer(new_team_id)
  true
  iex> team = portal_view(@sorcery, :my_portal, "?all_teams")[new_team_id]
  iex> team.name
  "My New Team"
  ```
  """
  alias Sorcery.Mutation.PreMutation
  

  # {{{ :init
  @doc """
  The first step of every mutation. You must have an existing portal in order to do any of this.

  ## Examples
      iex> m = Sorcery.Mutation.init(socket.assigns.sorcery, :my_portal)
      iex> is_struct(m)
      true
  """
  defdelegate init(state, portal_name), to: PreMutation
  @doc false
  defdelegate init(portal), to: PreMutation
  # }}}

  # {{{ update
  @doc """
  Kind of like a fusion between Kernel.update_in/3 and Map.update/4

  You need to pass in both a path list, and a default value in case the original value is nil.

  ## Examples
      iex> Sorcery.Mutation.update(m, [:player, 1, :age], 100, fn _original_age, latest_age -> latest_age + 1 end)
  """
  defdelegate update(mutation, path, cb), to: PreMutation
  # }}}

  # {{{ put
  @doc """
  Just like put_in, but for mutations.


  ## Examples
      iex> m = Sorcery.Mutation.put(m, [:player, 1, :health], 100)
  """
  defdelegate put(mutation, path, value), to: PreMutation
  # }}}

  # {{{ get
  @doc """
  Just like get_in, but for mutations. Always returns the latest version of a value or entity, with all the changes applied (if possible).

  ## Examples
      iex> player = Sorcery.Mutation.get(m, [:player, 1])
  """
  defdelegate get(mutation, path), to: PreMutation
  # }}}

  # {{{ get_original
  @doc """
  Just like get_in, but for the unchanged entity/value.


  ## Examples
      iex> m = Sorcery.Mutation.update(m, [:player, 1, :age], 100, &(&1 + 1))
      iex> old_player = Sorcery.Mutation.get_original(m, [:player, 1])
      iex> new_player = Sorcery.Mutation.get(m, [:player, 1])
      iex> new_player.age == old_player.age + 1
      true
  """
  defdelegate get_original(mutation, path), to: PreMutation
  # }}}

  # {{{ create_entity
  @doc """
  One of the benefits of a Mutation is that you can create entities using placeholder ids. 
  ## Examples
      iex> m = M.create_entity(m, :team, "?my_new_team", %{name: "My New Team"})
      iex> m = M.put(m, [:player, 1, :team_id], "?my_new_team")
      iex> # It always defaults to using the :id, but you can specify another field
      iex> m = M.put(m, [:player, 1, :team_id], "?my_new_team.my_field")

  """
  defdelegate create_entity(mutation, tk, lvar, body), to: PreMutation
  # }}}

  # {{{ delete_entity
  @doc """
  Sometimes we want to delete an entity entirely. Be careful, after the mutation is run, this cannot be undone
  """
  defdelegate delete_entity(mutation, tk, id), to: PreMutation
  # }}}

  # {{{ send_mutation(mutation)
  @doc """
  Sends the mutation to the corresponding Portal Server
  The Portal Server will then update its own data store.
  All portals that care about the changes will automatically update accordingly (including the one calling this function) 

  Returns the mutation passed in.

  To be clear, this does not return the new data you are waiting for. You probably won't need the return value.
  All the updates happen automatically, through some ~~magic~~  sorcery behind the scenes.
  """
  def send_mutation(%{portal: portal} = mutation) do
    %{parent_pid: parent} = portal
    msg = %{
      command: :run_mutation,
      portal: portal,
      mutation: mutation
    }
    send(parent, {:sorcery, msg})

    mutation
  end
  # }}}


end
