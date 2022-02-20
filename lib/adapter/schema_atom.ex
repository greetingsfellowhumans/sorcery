defmodule Sorcery.Adapter.SchemaAtom do
  use Norm
  alias Specs.Primative, as: T
  @moduledoc """
  Converts a module to an atom, and back again.
  """


  @contract struct_to_atom(T.struct()) :: T.atom()
  @doc """
  ## Examples
      iex> Adapter.SchemaAtom.struct_to_atom(%Interceptor{})
      :interceptor
  """
  def struct_to_atom(strct) do
    strct.__struct__
    |> Module.split() 
    |> List.last() 
    |> Macro.underscore()
    |> String.to_existing_atom()
  end



end
