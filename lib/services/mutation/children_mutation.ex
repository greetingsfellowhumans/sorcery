defmodule Sorcery.Mutation.ChildrenMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps
  #alias Sorcery.PortalServer.Portal

  defstruct [
    :old_data,
    version: 1,
    inserts: %{},
    updates: %{},
    deletes: %{},
  ]

  def init(parent_mutation, resolved_data) do
    body = 
      parent_mutation
      |> Map.from_struct()
      |> Map.put(:inserts, resolved_data.inserts)
      |> Map.put(:updates, resolved_data.updates)
      #|> Map.put(:deletes, resolved_data.deletes)
      |> Map.put(:deletes, resolve_deletes(parent_mutation, resolved_data.deletes))
    struct(__MODULE__, body)
  end

  defp resolve_deletes(parent_mutation, deletes) do
    Enum.reduce(deletes, %{}, fn {tk, ids}, acc ->
      entities = get_in_p(parent_mutation, [:portal, :known_matches, :data, tk]) || %{}
      Enum.reduce(ids, acc, fn id, acc ->
        entity = Map.get(entities, id, %{id: id})
        put_in_p(acc, [tk, id], entity)
      end)
    end)
  end

end
