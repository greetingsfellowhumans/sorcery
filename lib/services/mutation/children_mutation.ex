defmodule Sorcery.Mutation.ChildrenMutation do
  @moduledoc false
  #import Sorcery.Helpers.Maps
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
      |> Map.put(:deletes, resolved_data.deletes)
    struct(__MODULE__, body)
  end

end
