defmodule Sorcery.Mutation do
  defstruct [
    entities: %{},
    args: %{}
  ]

  def new(%{portal: _} = body) do
    body = Map.put_new(body, :args, %{})
    struct(__MODULE__, body)
  end
  
end
