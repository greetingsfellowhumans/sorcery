defmodule Sorcery.Schema.FieldType.Fk do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType


  defstruct [
    t: :fk,
    ecto_t: :id,
    module: nil,
    foreign_attr: :id,
    default: nil,
    has_many: nil,
    has_one: nil,
    belongs_to: nil,
    optional?: false,
  ]


  @impl true
  def new(args), do: struct(__MODULE__, args)

  def ecto_attrs(_field_struct), do: []

  @impl true
  def is_valid?(_, _, _), do: true


  @impl true
  def get_sd_field(_field_struct) do
    SD.positive_integer()
  end


end

