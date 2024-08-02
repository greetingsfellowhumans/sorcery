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
  iex> ### We can also use placeholder ids so that new entities (which haven't even been created yet) can be referenced by other entities.
  iex> m = M.create_entity(m, :team, "?my_new_team", %{name: "My New Team"})
  iex> m = M.put(m, [:player, 1, :team_id], "?my_new_team.id")
  iex> # This funny string is of course, the placeholder. But after we actually run the mutation, the team is created with a normal integer id.
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
  #alias Sorcery.LiveHelpers
  alias Sorcery.Mutation.PreMutation
  alias Sorcery.PortalServer.InnerState
  import Sorcery.Helpers.Maps
  
  # {{{ get_in(mutation, path)
  def get_in(mutation, path) do
    get_in_p(mutation, [:portal, :known_matches, :data] ++ path)
  end
  # }}}

  @doc ~s"""
  The function must return either: 
  :ok
  or
  {kind, reason}

  for example
  ```elixir
      {:error, "You can't do that."}
  ```

  This is used by LiveHelpers.optimistic_mutation to skip mutations and show flash messages instead.
  
  The function passed in takes two arguments, old_data and new_data
  Be careful, the new_data is not real. It is simply the best guess based on the current diff. By time the mutation reaches the portal server, it could be different!

  ## Examples
      iex> Mutation.validate(mutation, [:tk, :id, :some_attr], fn v -> 
        if v > 0, do: :ok, else: {:error, "Something went wrong"}
      end)
  """
  defdelegate validate(mutation, path, cb), to: PreMutation

  # {{{ :init
  @doc """
  The first step of every mutation. You must have an existing portal in order to do any of this.

  ## Examples
      iex> m = Sorcery.Mutation.init(socket.assigns.sorcery, :my_portal)
      iex> is_struct(m)
      true
  """
  defdelegate init(state, portal_name), to: PreMutation
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

  # {{{ skip(mutation, reason)
  @doc ~s"""
  Mark a mutation to NOT be sent to the PortalServer.
  Instead such a mutation will return an error tuple.
  When using the LiveView helper with optimistic_mutation/2, skipped mutations will trigger put_flash/3
  ## Examples
      iex> mutation = skip(mutation, :info, "Testing")
      iex> send_mutation(mutation, sorcery)
      {:error, {:skip, :info, "Testing"}}
  """
  def skip(mutation, reason), do: skip(mutation, :error, reason)
  def skip(mutation, kind, reason) do
    mutation
    |> Map.put(:skip?, true)
    |> Map.put(:skip_reason, reason)
    |> Map.put(:skip_kind, kind)
  end
  # }}}

  # {{{ send_mutation(mutation, inner_state, opts)
  @doc """
  Sends the mutation to the corresponding Portal Server
  The Portal Server will then update its own data store.
  All portals that care about the changes will automatically update accordingly (including the one calling this function) 

  Returns the mutation passed in.

  The return state will include a temp_portal, which is handy for both testing, and for optimistic updates. 
  When the PortalServer sends the new, fully updated data, then it will overwrite the portal and remove the temp_portal data.
  There are limitations to the temp_portal, and it should not be trusted too much.

  Takes an optional keyword list of options. Available options: :optimistic, :handle_fail, :handle_success

  ### :optimistic (true)
  When true, this will attempt an optimistic update. Does not work great when creating a new entity because we do not yet have the id.

  ### :handle_fail (nil)
  Expects nil, or a callback function of the shape `fn error, state -> state end`
  For example if you use Mutation.validate, which fails, then the error argument will be a map including keys :kind, :reason
  
  ### :handle_success (nil)
  Expects nil, or a callback function of the shape `fn data, state -> state end`
  DO NOT try to manually persist the data into a portal. That happens automatically after SorceryDb does some work.
  Instead this can be useful as a sanity test, or to verify that the transaction has, indeed, completed successfully.

  If you are using Sorcery.LiveHelpers, this takes a socket instead of state, allowing you to redirect, put_flash, etc.
  """
  def send_mutation(mutation, state), do: send_mutation(mutation, state, [])
  def send_mutation(%{skip?: true, skip_reason: reason, skip_kind: kind} = mutation, _state, opts) do
    if cb = Keyword.get(opts, :handle_fail) do
      child_pid = mutation.portal.child_pid
      msg = %{mutation: mutation}
            |> put_in_p([:args, :handle_fail], cb)
      err = %{reason: reason, kind: kind}
      Sorcery.PortalServer.Commands.RunMutation.on_fail(child_pid, msg, err)
    end
    {:error, {:skip, kind, reason}}
  end
  def send_mutation(%{portal: portal} = mutation, %InnerState{} = state, opts) do
    opts = Keyword.merge(default_opts(), opts)
    args = Enum.into(opts, %{})

    %{parent_pid: parent} = portal
    operations = mutation.operations |> Enum.reverse()
                 |> sanitize_operations()

    mutation = Map.put(mutation, :operations, operations)

    msg = %{
      args: args,
      command: :run_mutation,
      portal: portal,
      mutation: mutation
    }
    send(parent, {:sorcery, msg})

    state = if Keyword.get(opts, :optimistic), do: Sorcery.Mutation.Temp.add_temp_portal(state, mutation), else: state
    {:ok, state}
  end
  defp default_opts(), do: [optimistic: true]
  # }}}

  # {{{ sanitize_operations
  defp sanitize_operations(operations) do
    Enum.map(operations, fn
      {op, path, body} when is_struct(body) -> {op, path, body}
      {op, path, body} when is_map(body) ->
        body = Map.new(body, fn 
          {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
          {k, v} -> {k, v}
        end)
        {op, path, body}
      other -> other
    end)
  end
  # }}}


end
