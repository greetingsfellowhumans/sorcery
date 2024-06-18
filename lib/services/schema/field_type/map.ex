defmodule Sorcery.Schema.FieldType.Map do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType

  defstruct [
    :coll_of,
    :ecto_t,
    t: :integer,
    default: %{},
    optional?: true,
  ]


  @impl true
  def new(args) do
    struct(__MODULE__, args)
  end

  def ecto_attrs(_field_struct), do: %{}

  @impl true
  def is_valid?(_, _, _), do: true


  @impl true
  def get_sd_field(_field_struct) do
    SD.constant(%{})
  end


end
