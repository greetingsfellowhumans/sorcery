defmodule Sorcery.Mutation.SchemaMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps
  #alias Sorcery.PortalServer.Portal

  defstruct [
    entities: %{},
    deletes: %{},
    calling_pids: [],
  ]

  def init(children_mutation, pids) do
    body = %{
      entities: Map.merge(children_mutation.updates, children_mutation.inserts),
      deletes: children_mutation.deletes,
      calling_pids: pids
    }
    struct(__MODULE__, body)
  end

end
