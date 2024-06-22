defmodule Sorcery.Schema.FieldType.List do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType
  @default_min 0
  @default_max 10

  defstruct [
    :coll_of,
    :ecto_t,
    t: :list,
    min: @default_min,
    max: @default_max,
    default: nil,
    inner: %{},
    optional?: false,
    unique: false,
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
  def get_sd_field(%{min: min, max: max, coll_of: t} = field_struct) do
    inner_default = %{optional?: false, t: t}
    inner_given = Map.get(field_struct, :inner, %{})
    inner = Map.merge(inner_default, inner_given)
    inner_meta = %{optional?: false}

    inner_field = Sorcery.Schema.FieldType.new(inner, inner_meta)
    sd = inner_field.__struct__.get_sd_field(inner_field)
    SD.list_of(sd, min_length: min, max_length: max)
  end


end
