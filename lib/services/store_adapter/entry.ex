defmodule Sorcery.StoreAdapter do
  @moduledoc """
  A store adapter is a module that allows a PortalServer to access a data store by taking SrcQL, and converting it into something compatible with the specific store.
  """
  alias Sorcery.ReturnedEntities, as: RE

  @callback run_query(map(), module(), map()) :: {:ok, %RE{}}
  @callback run_mutation(map(), map()) :: {:ok, %RE{}}

end
