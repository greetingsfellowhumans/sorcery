defmodule Sorcery.Schema.FieldType.List do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType

  defstruct [
    :coll_of,
    :ecto_t,
    t: :integer,
    default: [],
    optional?: true,
  ]


  @impl true
  def new(%{coll_of: coll_of} = args) do
    body = %{ecto_t: {:array, coll_of}}
    body = Map.merge(body, args)
    struct(__MODULE__, body)
  end

  def ecto_attrs(_field_struct), do: []

  @impl true
  def is_valid?(_, _, _), do: true


  @impl true
  def get_sd_field(field_struct) do
    case Map.get(field_struct, :coll_of) do
      _ -> SD.constant([])
    end
  end


end
