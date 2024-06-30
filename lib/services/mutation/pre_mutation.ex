defmodule Sorcery.Mutation.PreMutation do
  @moduledoc false


  import Sorcery.Helpers.Maps
  alias Sorcery.PortalServer.Portal

  defstruct [
    :portal,
    version: 1,
    skip?: false,
    skip_reason: "Portal mutation already in progress.",
    skip_kind: :error,
    args: %{},
    entities: %{},
    old_data: %{},
    new_data: %{},
    deletes: %{},
    operations: []
  ]

  def init(sorcery_state, portal_name) do
    portal = get_in_p(sorcery_state, [:portals, portal_name])
    if portal do
      init(portal)
    else
      available_names = Map.get(sorcery_state, :portals, %{}) |> Map.keys()
      raise Sorcery.NoPortalInStateError,
        portal_name: portal_name,
        available_names: available_names
    end
  end
  defp init(nil) do
    raise Sorcery.NoPortalError
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

  

  def create_entity(%{skip?: true} = m, _tk, _lvar, _body), do: m
  def create_entity(mutation, tk, "?" <> _ = lvar, body) do
    body = Map.put(body, :id, lvar)
    __MODULE__.put(mutation, [tk, lvar], body)
  end


  def delete_entity(%{skip?: true} = m, _tk, _id), do: m
  def delete_entity(mutation, tk, id) do
    update_in_p(mutation, [:deletes, tk], [id], &([id | &1]))
  end

  def validate(%{skip?: true} = m, _path, _cb), do: m
  def validate(mutation, path, cb) do
    {original_data, new_data} = Sorcery.Mutation.Temp.get_split_data(mutation)
    o = get_in_p(original_data, path)
    n = get_in_p(new_data, path)
    case cb.(o, n) do
      :ok -> mutation
      {kind, reason} -> Sorcery.Mutation.skip(mutation, kind, reason)
    end
  end

end
