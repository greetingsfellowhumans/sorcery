defmodule Sorcery.Schema.FieldType.Boolean do
  @moduledoc false
  alias StreamData, as: SD
  @behaviour Sorcery.Schema.FieldType


  defstruct [
    t: :boolean,
    default: nil,
    optional?: true,
  ]


  @impl true
  def new(args), do: struct(__MODULE__, args)


  @impl true
  def is_valid?(:optional?, true, nil), do: true
  def is_valid?(_, _, true), do: true
  def is_valid?(_, _, false), do: true


  @impl true
  def get_sd_field(_field_struct) do
    SD.boolean()
  end


end
