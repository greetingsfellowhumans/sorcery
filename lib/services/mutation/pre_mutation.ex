defmodule Sorcery.Mutation.PreMutation do
  @moduledoc false


  import Sorcery.Helpers.Maps
  alias Sorcery.PortalServer.Portal

  defstruct [
    :portal,
    version: 1,
    args: %{},
    entities: %{},
    old_data: %{},
    new_data: %{},
    deletes: %{},
    operations: []
  ]

  def init(sorcery_state, portal_name) do
    init(sorcery_state.portals[portal_name])
  end
  def init(portal) do
    portal = Portal.freeze(portal)
    body = %{
      old_data: %{},# portal.known_matches.data,
      new_data: %{},#portal.known_matches.data,
      portal: portal
    }
    struct(__MODULE__, body)
  end

  def update(mutation, path, cb) do
    entry = {:update, path, cb}
    update_in_p(mutation, [:operations], [entry], &([entry | &1]))
    #old_v = get_in_p(mutation, [:old_data | path])
    #new_v = get_in_p(mutation, [:new_data | path])
    #v = cb.(old_v, new_v)
    #put_in_p(mutation, [:new_data | path], v)
  end
 
  def put(mutation, path, value) do
    entry = {:put, path, value}
    update_in_p(mutation, [:operations], [entry], &([entry | &1]))
    #put_in_p(mutation, [:new_data | path], value)
  end

  #def get(mutation, path) do
  #  get_in_p(mutation, [:new_data | path])
  #end
  #def get_original(mutation, path) do
  #  get_in_p(mutation, [:old_data | path])
  #end


  def create_entity(mutation, tk, "?" <> _ = lvar, body) do
    __MODULE__.put(mutation, [tk, lvar], body)
  end

  def delete_entity(mutation, tk, id) do
    update_in_p(mutation, [:deletes, tk], [id], &([id | &1]))
  end

end
