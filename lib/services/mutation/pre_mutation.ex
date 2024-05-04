defmodule Sorcery.Mutation.PreMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps
  alias Sorcery.PortalServer.Portal

  defstruct [
    version: 1,
    args: %{},
    old_data: %{},
    new_data: %{},
  ]

  def init(portal, opts \\ []) do
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
    delete_in(mutation, [:new_data, tk, id])
  end

end
