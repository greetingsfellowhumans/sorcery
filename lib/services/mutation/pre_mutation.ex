defmodule Sorcery.Mutation.PreMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps
  alias Sorcery.PortalServer.Portal

  defstruct [
    version: 1,
    args: %{},
    old_data: %{},
    new_data: %{},
    deletes: %{},
  ]

  def init(sorcery_state, portal_name) do
    parent_pid = Enum.find_value(sorcery_state.portals_to_parent, fn {pid, portals} ->
      names = Map.keys(portals)
      if portal_name in names, do: pid, else: nil
    end)
    init(sorcery_state.portals_to_parent[parent_pid][portal_name])
  end
  def init(portal) do
    portal = Portal.freeze(portal)
    body = %{
      old_data: portal.known_matches.data,
      new_data: portal.known_matches.data,
    }
    struct(__MODULE__, body)
  end

  def update(mutation, path, cb) do
    old_v = get_in_p(mutation, [:old_data | path])
    new_v = get_in_p(mutation, [:new_data | path])
    v = cb.(old_v, new_v)
    put_in_p(mutation, [:new_data | path], v)
  end
 
  def put(mutation, path, value) do
    put_in_p(mutation, [:new_data | path], value)
  end

  def get(mutation, path) do
    get_in_p(mutation, [:new_data | path])
  end
  def get_original(mutation, path) do
    get_in_p(mutation, [:old_data | path])
  end


  def create_entity(mutation, tk, "?" <> _ = lvar, body) do
    __MODULE__.put(mutation, [tk, lvar], body)
  end

  def delete_entity(mutation, tk, id) do
    update_in_p(mutation, [:deletes, tk], [id], &([id | &1]))
  end

end
