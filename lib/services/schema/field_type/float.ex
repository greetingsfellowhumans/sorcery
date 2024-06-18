defmodule Sorcery.Schema.FieldType.Float do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType
  @default_min -10_000.0
  @default_max 10_000.0


  defstruct [
    t: :float,
    min: nil,
    max: nil,
    default: nil,
    optional?: true,
  ]


  @impl true
  def new(args), do: struct(__MODULE__, args)

  def ecto_attrs(field_struct) do
    li = []
    if field_struct.min, do: [{:min, field_struct.min} | li], else: li
  end

  @impl true
  def is_valid?(:min,    nil, _value), do: true
  def is_valid?(:min, attr_v, value), do: value >= attr_v
  def is_valid?(:max,    nil, _value), do: true
  def is_valid?(:max, attr_v, value), do: value <= attr_v
  def is_valid?(_, _, _), do: true


  @impl true
  def get_sd_field(field_struct) do
    min = Map.get(field_struct, :min) || @default_min
    max = Map.get(field_struct, :max) || @default_max
    li = []
    li = [SD.float(min: min, max: max) | li]
    li = if field_struct.default, do: [SD.constant(field_struct.default) | li], else: li
    li = if field_struct.optional?, do: [nil | li], else: li
    SD.one_of(li)
  end


end
