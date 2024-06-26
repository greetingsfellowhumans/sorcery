defmodule Sorcery.Mutation.PreMutation do
  @moduledoc false


  import Sorcery.Helpers.Maps
  alias Sorcery.PortalServer.Portal

  defstruct [
    :portal,
    version: 1,
    skip?: false,
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
  defp init(portal) do
    portal = Portal.freeze(portal)
    body = %{
      old_data: %{},# portal.known_matches.data,
      new_data: %{},#portal.known_matches.data,
      skip?: !Enum.empty?(portal.temp_data),
      portal: portal
    }
    struct(__MODULE__, body)
  end

  def update(%{skip?: true} = m, _path, _cb), do: m
  def update(mutation, path, cb) do
    entry = {:update, path, cb}
    update_in_p(mutation, [:operations], [entry], &([entry | &1]))
  end
 

  def put(%{skip?: true} = m, _path, _cb), do: m
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

  def create_entity(%{skip?: true} = m, _tk, _lvar, _body), do: m
  def create_entity(mutation, tk, "?" <> _ = lvar, body) do
    body = Map.put(body, :id, lvar)
    __MODULE__.put(mutation, [tk, lvar], body)
  end


  def delete_entity(%{skip?: true} = m, _tk, _id), do: m
  def delete_entity(mutation, tk, id) do
    update_in_p(mutation, [:deletes, tk], [id], &([id | &1]))
  end

end
