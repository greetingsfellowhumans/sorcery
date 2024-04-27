defmodule Sorcery.Mutation do
  import Sorcery.Helpers.Maps

  defstruct [
    version: 1,
    args: %{},
    frozen_data: %{},
    inserts: %{},
    deletes: %{},
    updates: %{}
  ]

  def new(%{portal: _} = body) do
    body = Map.put_new(body, :args, %{})
    struct(__MODULE__, body)
  end

 
  def get(mutation, tk, id) do
    frozen  = get_in_p(mutation, [:frozen_data, tk, id]) || %{}
    updates = get_in_p(mutation, [:updates, tk, id])     || %{}
  end

end
