defmodule Sorcery.StoreAdapter do
  @moduledoc """
  A store adapter is a module that allows a PortalServer to access a data store by taking SrcQL, and converting it into something compatible with the specific store.

  Currently there are only two Adapters available: Ecto, and InMemory.
  InMemory is used behind the scenes by the LiveHelper, and is basically a noop, preferring to keep all data in the portal itself.
  While the `Sorcery.StoreAdapter.Ecto` adapter is used for dealing with serious backends like MySql and Postgres.
  """
  alias Sorcery.ReturnedEntities, as: RE

  @callback run_query(sorcery_state :: %Sorcery.PortalServer.InnerState{}, where_clauses :: list(%Sorcery.Query.WhereClause{}), finds :: map()) :: {:ok, %RE{}} | {:error, any()}
  @callback run_mutation(sorcery_state :: %Sorcery.PortalServer.InnerState{}, mutation :: %Sorcery.Mutation.ParentMutation{} | %Sorcery.Mutation.ChildrenMutation{} ) :: {:ok, %{
    updates: map(),
    inserts: map(),
    deletes: map(),
  }} | {:error, any()}

  def query(mod, state, clauses, finds) do
    mod.run_query(state, clauses, finds)
  end

  def mutation(mod, state, mutation) do
    mod.run_mutation(state, mutation)
  end

end
