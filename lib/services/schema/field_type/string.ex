defmodule Sorcery.Schema.FieldType.String do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType
  @default_min 0
  @default_max 25


  defstruct [
    t: :string,
     
    # @TODO
    # SD.string does not take min and max
    min: @default_min,
    max: @default_max,
    default: nil,
    optional?: true,
    unique: false,
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
  def get_sd_field(field_struct) do
    cb = generator(field_struct)
    SD.repeatedly(cb)
  end

  def generator(%{min: min, max: max}) do
    fn ->
      chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 !@#$%^&*(){}()[]':;,.<>/?" |> String.split("") |> Enum.filter(&(&1 != ""))
      count = Enum.random(min..max)
      Enum.take_random(chars, count) |> Enum.join("")
    end
  end


end
