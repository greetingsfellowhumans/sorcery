defmodule Sorcery.StoreAdapter.InMemory do
  @moduledoc """
  This is the adapter for keeping everything in plain elixir maps. Quick and easy. Also the default mode for LiveViews. 
  ```

  """
  @behaviour Sorcery.StoreAdapter
  alias Sorcery.ReturnedEntities, as: RE


  @impl true
  def run_query(_, _, _), do: { :ok, RE.new() }

  @impl true
  def run_mutation(_, _), do: { :ok, RE.new() }

end
