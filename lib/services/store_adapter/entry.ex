defmodule Sorcery.StoreAdapter do
  @moduledoc """
  A store adapter is a module that allows a PortalServer to access a data store by taking SrcQL, and converting it into something compatible with the specific store.
  """
  alias Sorcery.ReturnedEntities, as: RE

  @callback run_query(sorcery_state :: map(), where_clauses :: list(%Sorcery.Query.WhereClause{}), finds :: map()) :: {:ok, %RE{}} | {:error, any()}
  @callback run_mutation(sorcery_state :: map(), mutation :: %Sorcery.Mutation.ParentMutation{} | %Sorcery.Mutation.ChildrenMutation{} ) :: {:ok, %{
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
