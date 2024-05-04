defmodule Sorcery.Schema.FieldType.String do
  @moduledoc false
  use Norm
  #import Sorcery.Specs
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType


  defstruct [
    t: :string,
     
    # @TODO
    # SD.string does not take min and max
    min: nil,
    max: nil,
    default: nil,
    optional?: true,
  ]


  @impl true
  def new(args), do: struct(__MODULE__, args)


  @impl true
  def is_valid?(:min,    nil, _value), do: true
  def is_valid?(:min, attr_v, value), do: String.length(value) >= attr_v
  def is_valid?(:max,    nil, _value), do: true
  def is_valid?(:max, attr_v, value), do: String.length(value) <= attr_v
  def is_valid?(_, _, _), do: true

  @impl true
  def base_norm_spec(), do: &is_binary/1


  @impl true
  def get_sd_field(field_struct) do
    #min = Map.get(field_struct, :min)
    #max = Map.get(field_struct, :max)
    opts = :utf8
    #opts = [{:utf8, true}]
    #opts = if min, do: [{:min, min} | opts], else: opts
    #opts = if max, do: [{:max, max} | opts], else: opts

    li = []
    li = [SD.string(opts) | li]
    li = if field_struct.default, do: [SD.constant(field_struct.default) | li], else: li
    li = if field_struct.optional?, do: [nil | li], else: li
    SD.one_of(li)
  end


end
