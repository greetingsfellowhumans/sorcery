defmodule Sorcery.Schema.FieldType.Fk do
  use Norm
  import Sorcery.Specs
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
    optional?: true,
  ]


  @impl true
  def new(args), do: struct(__MODULE__, args)

  @moduledoc """
  Everything below this line is @TODO
  """
  def ecto_attrs(field_struct) do
    []
  end

  @impl true
  def is_valid?(:tk,    nil, _value), do: false
  def is_valid?(_, _, _), do: true

  @impl true
  def base_norm_spec(), do: &is_integer/1

  @impl true
  def get_sd_field(field_struct) do
    li = []
    li = [SD.positive_integer() | li]
    li = if field_struct.default, do: [SD.constant(field_struct.default) | li], else: li
    li = if field_struct.optional?, do: [nil | li], else: li
    SD.one_of(li)
  end


end
